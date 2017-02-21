//
//  AccountVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import KeychainAccess
//import SwiftyJSON

class AccountVC: UIViewController, UITextFieldDelegate {

    // MARK: Interface
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.

        let defaults = UserDefaults.standard
        if let email = defaults.string(forKey: "email") {
            loginTextField.text = email
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        //saveButton.enabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
        // navigationItem.title = textField.text
    }
    
    // MARK: - Keychain Stuff
    
    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        if let email = loginTextField.text, let pass = passwordTextField.text {

            // TODO - use User object

            let defaults = UserDefaults.standard
            print("Saving email: \(email) ...")
            defaults.set(email, forKey: "email")
            print("Saving pass: \(pass) ...")
            let keychain = Keychain(service: "***REMOVED***")
            keychain[email] = pass
        }

        APIManager.sharedInstance.login(completion: completedLogin)
        //dismiss(animated: true, completion: nil)
        //navigationController!.popViewController(animated: true)
    }
    
    // MARK: - Navigation

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("Preparing for segue ...")
    }
    */

}

// MARK: - Completion Handlers
extension AccountVC {

    func completedLogin(success: Bool) {
        if success {
            print("Logged in")
            // TODO - handle User?
            dismiss(animated: true, completion: nil)
        } else {
            // TODO - how best to handle this?
            print("Failed to login")
        }
    }

    // func completedSignup(json: JSON?, error: Error?) -> Void {}

}
