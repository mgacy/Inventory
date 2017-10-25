//
//  CurrentUserManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import KeychainAccess
import SwiftyJSON

class CurrentUserManager {

    typealias CompletionHandlerType = (BackendError?) -> Void

    // MARK: - Properties

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
            log.warning("CurrentUserManager: unable to get email or password"); return
        }

        // It doesn't make sense to have an authHandler unless we have a corresponding User

        /// TODO: I don't like instantiating a User with a fake id here. Currently, the existence of a user functions to tell AppDelegate whether we need to log in. Should we use `userExists()` to communicate this instead? That way we could wait until successful login to create the User.

        user = User(id: 1, email: email)

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

        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler!)
    }

    fileprivate func removeUser() {
        self.email = nil
        self.password = nil
        keychain["authToken"] = nil
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

        authHandler!.login { json, error in
            guard error == nil else {
                log.error("\(#function) FAILED : \(error!)")
                self.authHandler = nil
                return completion(BackendError.network(error: error!))
            }
            // AuthenticationHandler.login ensures json != nil, but we need to unwrap json.
            guard let json = json else {
                log.error("\(#function) FAILED : unable to get JSON")
                self.authHandler = nil
                return completion(BackendError.myError(error: "Unable to get JSON from response."))
            }

            /// TODO: move parsing out somewhere else?
            //let user: [String: JSON] = json["user"].dictionaryValue
            //let userID: Int = user["id"]!.intValue

            //let stores: [JSON] = user["stores"]!.arrayValue
            //let defaultStore = stores[0]
            //let defaultStoreID: Int = defaultStore["id"].intValue

            let userID = json["user"]["id"].intValue
            let defaultStoreID: Int = json["user"]["default_store"]["id"].intValue

            /// TODO: simply call .createUser(userID:email:password:)?

            self.email = email
            self.password = password
            self.storeID = defaultStoreID
            self.user = User(id: userID, email: email)
            APIManager.sharedInstance.configSession(self.authHandler!)
            completion(nil)
        }
    }

    public func signUp(username: String, email: String, password: String, completion: @escaping CompletionHandlerType) {

        Alamofire.request(Router.signUp(username: username, email: email, password: password))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)

                    //let user: [String: JSON] = json["user"].dictionaryValue
                    //let userID: Int = user["id"]!.intValue
                    let userID = json["user"]["id"].intValue

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
