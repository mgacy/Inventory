//
//  LoginViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import KeychainAccess
import PKHUD
//import SwiftyJSON

class LoginViewController: UIViewController {

    // MARK: Properties
    var userManager: CurrentUserManager!

    // MARK: Interface
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        /// TODO: enable signup
        signupButton.isEnabled = false

        loginTextField.delegate = self
        passwordTextField.delegate = self

        if let user = userManager.user {
            loginTextField.text = user.email
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - User interaction

    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        login()
    }

    //@IBAction func signupButtonPressed(_ sender: AnyObject) {}

    func login() {
        guard let email = loginTextField.text, let pass = passwordTextField.text else {
            return
        }
        HUD.show(.progress)
        userManager.login(email: email, password: pass, completion: completedLogin)
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
        log.verbose("Preparing for segue ...")
    }
    */

}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case loginTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            /// TODO: perform validation

            // Hide the keyboard.
            textField.resignFirstResponder()
            login()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    /*
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the LogIn button while editing.
        loginButton.isEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
        loginButton.isEnabled = true
    }
    */
}

// MARK: - Completion Handlers
extension LoginViewController {

    func completedLogin(error: BackendError? = nil) {
        guard error == nil else {
            log.error("Failed to login")
            switch error! {
            case .authentication:
                HUD.flash(.error, delay: 1.0)
            default:
                HUD.flash(.error, delay: 1.0)
            }
            return
        }
        log.verbose("Logged in")
        HUD.hide()
        dismiss(animated: true, completion: nil)
    }

    // func completedSignup(json: JSON?, error: Error?) -> Void {}

}
