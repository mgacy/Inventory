//
//  CurrentUserManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Alamofire
import RxSwift
import KeychainAccess

enum AuthenticationState {
    case signedIn
    case signedOut
}

class CurrentUserManager {

    typealias CompletionHandlerType = (BackendError?) -> Void

    // MARK: - Properties
    var authenticationState: AuthenticationState = .signedOut
    let currentUser = BehaviorSubject<RemoteUser?>(value: nil)
    var storeID: Int? {
        get {
            return defaults.integer(forKey: "store")
        }
        set {
            if let valueToSave = newValue {
                defaults.set(valueToSave, forKey: "store")
            } else { // they set it to nil, so delete it
                defaults.removeObject(forKey: "store")
            }
        }
    }

    // MARK: - Private
    private var credentialsManager: CredentialsManagerType
    private let storageManager: UserStorageManagerType
    private let defaults: UserDefaults
    private let keychain: Keychain

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.keychain = Keychain(service: "***REMOVED***")
        self.credentialsManager = CredentialsManager(keychain: self.keychain)
        self.storageManager = UserStorageManager()

        if let user = storageManager.read(), let password = credentialsManager.password {
            self.authenticationState = .signedIn
            self.currentUser.onNext(user)

            let authHandler = AuthenticationHandler(keychain: keychain, email: user.email, password: password)
            APIManager.sharedInstance.configSession(authHandler)
        } else {
            self.authenticationState = .signedOut
        }
    }

    // MARK: -

    fileprivate func createUser(email: String, password: String, user: RemoteUser) {
        authenticationState = .signedIn
        currentUser.onNext(user)
        storeID = user.defaultStore.remoteID

        credentialsManager.store(password: password)
        storageManager.store(user: user)

        let authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler)
    }

    fileprivate func removeUser() {
        credentialsManager.clear()
        storageManager.clear()
        authenticationState = .signedOut
        currentUser.onNext(nil)
    }

    // MARK: - Authentication

    public func login(email: String, password: String, completion: @escaping CompletionHandlerType) {

        /// TODO: handle pre-existing user?

        // We login with AuthenticationHandler since it is responsible for maintaining the token.
        // Something long-lasting like an access token in an OAuth2 scheme should be the
        // responsibility of the same object handling the email and password, while the refresh
        // token could be handled by another one. However, the access token is currently short-lived.
        let authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)

        authHandler.login { remoteUser, error in
            guard error == nil else {
                log.error("\(#function) FAILED : \(error!)")
                return completion(BackendError.network(error: error!))
            }
            // AuthenticationHandler.login ensures json != nil, but we need to unwrap json.
            guard let user = remoteUser else {
                log.error("\(#function) FAILED : unable to get JSON")
                return completion(BackendError.myError(error: "Unable to get JSON from response."))
            }

            self.createUser(email: email, password: password, user: user)
            completion(nil)
        }
    }

    public func signUp(firstName: String, lastName: String, email: String, password: String, completion: @escaping CompletionHandlerType) {
        let decoder = JSONDecoder()
        Alamofire.request(Router.signUp(firstName: firstName, lastName: lastName, email: email, password: password))
            .validate()
            .responseDecodableObject(decoder: decoder) { (response: DataResponse<RemoteUser>) in
                switch response.result {
                case .success(let value):
                    log.verbose("\(#function) - response: \(response)")
                    self.createUser(email: email, password: password, user: value)
                    completion(nil)
                case .failure(let error):
                    log.error("\(#function) FAILED : \(error)")
                    completion(BackendError.network(error: error))
                }
        }
    }

    /// TODO: public func confirm(withToken token: String) {}

    public func logout() -> Observable<Bool> {
        /// TODO: removeUser first, regardless of response.result?
        return APIManager.sharedInstance.logout()
            .do(onNext: { result in
                switch result {
                case true:
                    APIManager.sharedInstance.configSession(nil)
                    self.removeUser()
                case false:
                    APIManager.sharedInstance.configSession(nil)
                    self.removeUser()
                }
            })
    }

}

// MARK: -

// MARK: - Persistence

protocol UserStorageManagerType {
    //associatedtype UserType: Codable

    //func store(user: UserType)
    func store(user: RemoteUser)
    //func read() -> UserType?
    func read() -> RemoteUser?
    func clear()
}

class UserStorageManager: UserStorageManagerType {
    //typealias UserType = User

    private let encoder: JSONEncoder
    private let archiveURL: URL

    init() {
        encoder = JSONEncoder()
        archiveURL = UserStorageManager.getDocumentsURL().appendingPathComponent("user")
    }

    func store(user: RemoteUser) {
        // should incorporate better error handling
        do {
            let data = try encoder.encode(user)
            guard NSKeyedArchiver.archiveRootObject(data, toFile: archiveURL.path) else {
                fatalError("Could not store data to url")
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func read() -> RemoteUser? {
        if let data = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? Data {
            let decoder = JSONDecoder()
            do {
                let user = try decoder.decode(RemoteUser.self, from: data)
                return user
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            return nil
        }
    }

    func clear() {
        // should incorporate better error handling
        do {
            try FileManager.default.removeItem(at: archiveURL)
        } catch {
            fatalError("Could not delete data from url")
        }
    }

    // MARK: - Helper Methods

    private static func getDocumentsURL() -> URL {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        } else {
            // should incorporate better error handling
            fatalError("Could not retrieve documents directory")
        }
    }

}

// MARK: - A

protocol CredentialsManagerType {
    var accessToken: String? { get set }
    var password: String? { get set }

    func store(password: String)
    func clear()
}

class CredentialsManager: CredentialsManagerType {
    var accessToken: String? {
        set {
            if let valueToSave = newValue {
                keychain["authToken"] = valueToSave
            } else { // they set it to nil, so delete it
                keychain["authToken"] = nil
            }
        }
        get {
            // try to load from keychain
            if let token = try? keychain.get("authToken") {
                return token
            } else {
                return nil
            }
        }
    }
    var password: String? {
        get {
            // try to load from keychain
            if let pass = try? keychain.get("password") {
                return pass
            } else {
                return nil
            }
        }
        set {
            if let valueToSave = newValue {
                keychain["password"] = valueToSave
            } else { // they set it to nil, so delete it
                keychain["password"] = nil
            }
        }
    }

    // MARK: - Private
    private let keychain: Keychain

    // MARK: - Lifecycle

    init(keychain: Keychain) {
        self.keychain = keychain
    }

    // MARK: -

    func store(password: String) {
        self.password = password
    }

    func clear() {
        accessToken = nil
        password = nil
    }

}
