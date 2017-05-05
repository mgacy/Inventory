//
//  InitialSignUpVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import KeychainAccess
import PKHUD
import SwiftyJSON

class InitialSignUpVC: UIViewController, UITextFieldDelegate, SegueHandler {

    // MARK: Properties
    var managedObjectContext: NSManagedObjectContext!
    var userManager: CurrentUserManager!

    // Segue
    enum SegueIdentifier: String {
        case showMain = "showTabController"
        case showSignUp = "showSignUpController"
        //case showInventories = "showInventories"
        //case showLogin = "showLogin"
    }

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
        userManager.signUp(username: username, email: email, password: pass, completion: completedSignup)
        //APIManager.sharedInstance.signUp(username: username, email: email, password: pass, completion: completedSignup)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showMain:

            // Get the new view controller.
            guard
                let tabBarController = segue.destination as? UITabBarController,
                let inventoryNavController = tabBarController.viewControllers![0] as? UINavigationController,
                let controller = inventoryNavController.topViewController as? InventoryDateTVC
            else {
                fatalError("Wrong view controller type")
            }

            // Inject dependencies
            controller.managedObjectContext = managedObjectContext
            controller.userManager = userManager

            // Sync with completion handler from the new view controller.
            _ = SyncManager(context: managedObjectContext, storeID: userManager.storeID!, completionHandler: controller.completedSync)
        case .showSignUp:
            log.verbose("SignUpSegue")

            // ...

            // Inject dependencies
            //controller.managedObjectContext = managedObjectContext
            //controller.userManager = userManager
        }
    }

}

// MARK: - Completion Handlers
extension InitialSignUpVC {

    func completedSignup(json: JSON?, error: Error?) {
        guard error == nil else {
            log.error("\(#function) FAILED: unable to sign up")
            HUD.flash(.error, delay: 1.0); return
        }
        log.verbose("Signed up")

        guard let email = loginTextField.text, let pass = passwordTextField.text else {
            return
        }
        userManager.createUser(email: email, password: pass)
        performSegue(withIdentifier: .showMain)
    }

}
