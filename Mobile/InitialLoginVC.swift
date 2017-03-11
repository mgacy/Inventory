//
//  InitialLoginVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import KeychainAccess
import PKHUD
//import SwiftyJSON

class InitialLoginVC: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    var userManager: CurrentUserManager!

    // Segue
    //let InventorySegue = "showInventories"
    //let OrderSegue = "showOrders"
    //let InvoiceSegue = "showInvoices"
    //let SettingSegue = "showSettings"
    let MainSegue = "showTabController"
    let SignUpSegue = "showSignUpController"

    // MARK: Interface
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

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

    //@IBAction func signupButtonPressed(_ sender: AnyObject) {}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case MainSegue:

            // Get the new view controller.
            // TODO - use guards here?
            let tabBarController = segue.destination as! UITabBarController
            let inventoryNavController = tabBarController.viewControllers![0] as! UINavigationController
            let controller = inventoryNavController.topViewController as! InventoryDateTVC

            // Inject dependencies
            controller.userManager = userManager

            // Sync with completion handler from the new view controller.
            _ = SyncManager(storeID: userManager.storeID!, completionHandler: controller.completedLogin)
        case SignUpSegue:

            // Get the new view controller.
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? InitialSignUpVC
                else {
                    debugPrint("\(#function) FAILED : unable to get destination"); return
            }

            // Pass dependencies to the new view controller.
            destinationController.userManager = userManager

        default:
            break
        }
    }

}

// MARK: - Completion Handlers
extension InitialLoginVC {

    func completedLogin(success: Bool) {
        if success {
            print("Logged in")
            // TODO: change so we only createUser() on success
            performSegue(withIdentifier: MainSegue, sender: self)
        } else {
            print("Failed to login")
            userManager.removeUser()
            // TODO - how best to handle this?
            HUD.flash(.error, delay: 1.0); return
        }
    }

}
