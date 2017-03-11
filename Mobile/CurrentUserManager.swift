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

    static let sharedInstance = CurrentUserManager()

    var user: User?

    // TODO - why are we holding on to the AuthenticationHandler instead of simply configuring and
    // passing off to APIManager?
    private var authHandler: AuthenticationHandler?
    private let defaults: UserDefaults
    private let keychain: Keychain
    private var email: String? {
        get {
            return defaults.string(forKey: "email")
        }
        set {
            defaults.set(email, forKey: "email")
        }
    }
    private var password: String? {
        get {
            // try to load from keychain
            guard let passEntry = try? keychain.get("password") else {
                print("FAILED: unable to access keychain"); return nil
            }
            guard let pass = passEntry else {
                print("FAILED: unable to get password from keychain"); return nil
            }
            print("Got password from keychain")
            return pass
        }
         set {
            keychain["password"] = password
        }
    }

    var storeID: Int? {
        get {
            return defaults.integer(forKey: "store")
            //let x = defaults.integer(forKey: "store")
            //print("get storeID: \(x)")
            //return x
        }
        set {
            print("set storeID: \(storeID)")
            defaults.set(storeID, forKey: "store")
        }
    }


    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.keychain = Keychain(service: "***REMOVED***")

        // TODO - should we store User as a dict or just retrieve info from the server?

        guard let email = email, let password = password else {
            // TEMP
            //createUser(email: "stevey@mgacy.com", password: "password")
            print("CurrentUserManager: unable to get email or password"); return
        }

        // It doesn't make sense to have an authHandler unless we have a corresponding User

        user = User(id: 1, email: email)

        // TODO - should we always login on init?
        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler!)
    }

    // MARK: -

    func createUser(email: String, password: String) {
        defaults.set(email, forKey: "email")
        keychain["password"] = password
        user = User(id: 1, email: email)

        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)
        APIManager.sharedInstance.configSession(authHandler!)
    }

    func removeUser() {
        defaults.removeObject(forKey: "email")
        keychain["password"] = nil
        keychain["authToken"] = nil
        user = nil
        authHandler = nil
    }


    // MARK: -

    public func login(email: String, password: String, completion: @escaping (Bool) -> Void) {

        // TODO - handle pre-existing user?
        // TODO - handle pre-existing authHandler?

        // We login with AuthenticationHandler since it is responsible for maintaining the token
        authHandler = AuthenticationHandler(keychain: keychain, email: email, password: password)

        authHandler!.login(completion: {(json: JSON?, error: Error?) -> Void in
            // TODO - combine the two guards?
            // TODO - does AuthenticationHandler.login already ensure json != nil?
            // TODO - set authHandler back to nil / self.removeUser() if guard fails?
            guard error == nil else {
                print("\(#function) FAILED : \(error)")
                return completion(false)
            }
            guard let json = json else {
                print("\(#function) FAILED : \(error)")
                return completion(false)
            }

            let user: Dictionary<String, JSON> = json["user"].dictionaryValue
            let userID: Int = user["id"]!.intValue
            let stores: Array<JSON> = user["stores"]!.arrayValue

            // TODO - can we safely assume all users will have at least one store?
            let defaultStore = stores[0]
            let defaultStoreID: Int = defaultStore["id"].intValue

            // TESTING
            //print("login response: \(json)")
            //print("user: \(user)")
            //print("userID: \(userID)")
            //print("stores: \(stores)")
            //print("defaultStore: \(defaultStore)")
            //print("defaultStoreID: \(defaultStoreID)")
            //print("storeID: \(self.storeID)")

            //self.defaults.set(defaultStoreID, forKey: "store")
            //self.defaults.set(email, forKey: "email")
            //self.keychain["password"] = password

            self.email = email
            self.password = password
            self.storeID = defaultStoreID

            self.user = User(id: userID, email: email)

            APIManager.sharedInstance.configSession(self.authHandler!)

            completion(true)
        })
    }

    public func signUp(username: String, email: String, password: String, completion: @escaping (JSON?, Error?) -> Void) {

        Alamofire.request(Router.signUp(username: username, email: email, password: password))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)

                    let user: Dictionary<String, JSON> = json["user"].dictionaryValue
                    let userID: Int = user["id"]!.intValue

                    self.defaults.set(email, forKey: "email")
                    self.keychain["password"] = password
                    self.user = User(id: userID, email: email)

                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func logout(completion: @escaping (Bool) -> Void) {
        // TODO - removeUser first, regardless of response.result?
        Alamofire.request(Router.logout)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    print("\n\(#function) - response: \(response)\n")

                    APIManager.sharedInstance.configSession(nil)
                    self.removeUser()
                    completion(true)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")

                    APIManager.sharedInstance.configSession(nil)
                    self.removeUser()
                    completion(false)
                }
        }
    }

}
