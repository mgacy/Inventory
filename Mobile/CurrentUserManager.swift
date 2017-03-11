//
//  CurrentUserManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import KeychainAccess

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

}
