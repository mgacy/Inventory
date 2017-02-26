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

    let defaults: UserDefaults
    let keychain: Keychain

    var user: User?

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.keychain = Keychain(service: "***REMOVED***")

        if let email = defaults.string(forKey: "email") {
            user = User(id: 1, email: email)
        } else {
            // TEMP
            print("CurrentUserManager: no email")
            //createUser(email: "stevey@mgacy.com", password: "password")
        }

    }

    func createUser(email: String, password: String) {
        defaults.set(email, forKey: "email")
        keychain["password"] = password
        user = User(id: 1, email: email)
    }

    func removeUser() {
        defaults.removeObject(forKey: "email")
        keychain["password"] = nil
        keychain["authToken"] = nil
        user = nil
    }

}
