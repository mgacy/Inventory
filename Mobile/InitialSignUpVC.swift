//
//  InitialSignUpVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import KeychainAccess
import PKHUD
import SwiftyJSON

class InitialSignUpVC: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
    //let userManager: CurrentUserManager

    // Segue
    //let InventorySegue = "showInventories"
    //let LoginSegue = "showLogin"
    let MainSegue = "showTabController"
    let SignUpSegue = "showSignUpController"

    // MARK: Interface
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

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

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func signupButtonPressed(_ sender: AnyObject) {
        guard let username = usernameTextField.text else {
            return
        }
        guard let email = loginTextField.text else {
            return
        }
        guard let pass = passwordTextField.text else {
            return
        }

        HUD.show(.progress)
        APIManager.sharedInstance.signUp(username: username, email: email, password: pass, completion: completedSignup)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case MainSegue:

            // Get the new view controller.
            let tabBarController = segue.destination as! UITabBarController
            let inventoryNavController = tabBarController.viewControllers![0] as! UINavigationController
            let controller = inventoryNavController.topViewController as! InventoryDateTVC

            // Sync with completion handler from the new view controller.
            _ = SyncManager(completionHandler: controller.completedLogin)
        case SignUpSegue:
            print("b")
        default:
            break
        }
    }

}

// MARK: - Completion Handlers
extension InitialSignUpVC {

    func completedSignup(json: JSON?, error: Error?) {
        guard error == nil else {
            print("Failed to sign up")
            HUD.flash(.error, delay: 1.0); return
        }
        print("Signed up")

        guard let email = loginTextField.text, let pass = passwordTextField.text else {
            return
        }
        userManager.createUser(email: email, password: pass)
        performSegue(withIdentifier: MainSegue, sender: self)
    }
    
}

