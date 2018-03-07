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
    let currentUser = BehaviorSubject<User?>(value: nil)
    var user: User?

    /// TODO: why are we holding on to the AuthenticationHandler instead of simply configuring and passing off to APIManager?
    private var authHandler: AuthenticationHandler?
    private let defaults: UserDefaults
    private let keychain: Keychain
    private var email: String? {
        get {
            return defaults.string(forKey: "email")
        }
        set {
            if let valueToSave = newValue {
                defaults.set(valueToSave, forKey: "email")
            } else { // they set it to nil, so delete it
                defaults.removeObject(forKey: "email")
            }
        }
    }
    private var password: String? {
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

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.keychain = Keychain(service: "***REMOVED***")

        /// TODO: should we store User as a dict or just retrieve info from the server?

        guard let email = email, let password = password else {
            //authenticationState = .signedOut
            log.warning("CurrentUserManager: unable to get email or password"); return
        }

        // It doesn't make sense to have an authHandler unless we have a corresponding User

        /// TODO: I don't like instantiating a User with a fake id here. Currently, the existence of a user functions to tell AppDelegate whether we need to log in. Should we use `userExists()` to communicate this instead? That way we could wait until successful login to create the User.

        authenticationState = .signedIn
        user = User(id: 1, email: email)
        currentUser.onNext(user)

        /// TODO: should we always login on init?
        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler!)
    }

    // MARK: -

    fileprivate func createUser(userID: Int, email: String, password: String) {
        self.email = email
        self.password = password
        /// TODO: self.storeID = ?
        user = User(id: userID, email: email)
        authenticationState = .signedIn
        self.currentUser.onNext(user)

        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler!)
    }

    fileprivate func removeUser() {
        self.email = nil
        self.password = nil
        keychain["authToken"] = nil
        authenticationState = .signedOut
        currentUser.onNext(nil)
        user = nil
        authHandler = nil
    }

    // MARK: - Authentication

    public func login(email: String, password: String, completion: @escaping CompletionHandlerType) {

        /// TODO: handle pre-existing user?

        // We login with AuthenticationHandler since it is responsible for maintaining the token.
        // Something long-lasting like an access token in an OAuth2 scheme should be the
        // responsibility of the same object handling the email and password, while the refresh
        // token could be handled by another one. However, the access token is currently short-lived.
        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)

        authHandler!.login { remoteUser, error in
            guard error == nil else {
                log.error("\(#function) FAILED : \(error!)")
                self.authHandler = nil
                return completion(BackendError.network(error: error!))
            }
            // AuthenticationHandler.login ensures json != nil, but we need to unwrap json.
            guard let user = remoteUser else {
                log.error("\(#function) FAILED : unable to get JSON")
                self.authHandler = nil
                return completion(BackendError.myError(error: "Unable to get JSON from response."))
            }

            let userID = user.remoteID
            let defaultStoreID = user.defaultStore.remoteID

            /// TODO: simply call .createUser(userID:email:password:)?

            self.email = email
            self.password = password
            self.storeID = defaultStoreID
            self.authenticationState = .signedIn
            self.user = User(id: userID, email: email)
            self.currentUser.onNext(self.user)

            APIManager.sharedInstance.configSession(self.authHandler!)
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
                    let userID = value.remoteID
                    self.createUser(userID: userID, email: email, password: password)
                    completion(nil)
                case .failure(let error):
                    log.error("\(#function) FAILED : \(error)")
                    completion(BackendError.network(error: error))
                }
        }
    }

    /// TODO: public func confirm(withToken token: String) {}

    public func logout(completion: @escaping (Bool) -> Void) {
        /// TODO: removeUser first, regardless of response.result?
        APIManager.sharedInstance.logout(completion: {(success: Bool) -> Void in
            switch success {
            case true:
                APIManager.sharedInstance.configSession(nil)
                self.removeUser()
                completion(true)
            case false:
                APIManager.sharedInstance.configSession(nil)
                self.removeUser()
                completion(false)
            }
        })
    }

}

// MARK: -

// MARK: - Persistence

protocol UserStorageManagerType {
    func store(user: User)
    func read() -> User?
    func clear()
}

class UserStorageManager: UserStorageManagerType {
    private let encoder: JSONEncoder
    private let archiveURL: URL

    init() {
        encoder = JSONEncoder()
        archiveURL = UserStorageManager.getDocumentsURL().appendingPathComponent("user")
    }

    func store(user: User) {
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

    func read() -> User? {
        if let data = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? Data {
            let decoder = JSONDecoder()
            do {
                let user = try decoder.decode(User.self, from: data)
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
