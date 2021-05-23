//
//  User.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import KeychainAccess

class User: Codable {

    //private let defaults = UserDefaults.standard
    //private let keychain: Keychain

    var id: Int
    var email: String
    //var password: String?
    //var firstName: String
    //var lastName: String
    /*
    var email: String? {
        set {
            //let defaults = UserDefaults.standard
            if let valueToSave = newValue {
                defaults.set(valueToSave, forKey: "email")
            }
        }
        get {
            //let defaults = UserDefaults.standard
            return defaults.string(forKey: "email")
        }
    }

    var password: String? {
        set {
            guard let email = email else { return }

            if let valueToSave = newValue {
                keychain[email] = valueToSave
            } else { // they set it to nil, so delete it
                keychain[email] = nil
            }
        }
        get {
            guard let email = email else { return nil }
            do {
                let pass = try keychain.get(email)
                return pass
            } catch {
                log.error("FAILED: unable to access keychain: \(error)")
                return nil
            }
        }
    }
    */
    // MARK: - Lifecycle

    init(id: Int, email: String) {
        //keychain = Keychain(service: "***REMOVED***")
        self.id = id
        self.email = email
    }

}
