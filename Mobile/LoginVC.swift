//
//  LoginVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import KeychainAccess
import PKHUD
//import SwiftyJSON

class LoginVC: UIViewController, UITextFieldDelegate {

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

        // Do any additional setup after loading the view.
        /// TODO: enable signup
        signupButton.isEnabled = false

        if let user = userManager.user {
            loginTextField.text = user.email
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
        // Disable the LogIn button while editing.
        loginButton.isEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
    }

    // MARK: - User interaction

    @IBAction func loginButtonPressed(_ sender: AnyObject) {
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

// MARK: - Completion Handlers
extension LoginVC {

    func completedLogin(success: Bool) {
        if success {
            log.info("Logged in")
            HUD.hide()
            dismiss(animated: true, completion: nil)
        } else {
            /// TODO: how best to handle this?
            HUD.flash(.error, delay: 1.0); return
            log.error("Failed to login")
        }
    }

    // func completedSignup(json: JSON?, error: Error?) -> Void {}

}
