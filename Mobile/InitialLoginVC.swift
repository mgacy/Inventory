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
    let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
    //let userManager: CurrentUserManager

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
        //loginButton.enabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
    }

    // MARK: - Keychain Stuff

    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        guard let email = loginTextField.text, let pass = passwordTextField.text else {
            return
        }
        HUD.show(.progress)
        userManager.createUser(email: email, password: pass)
        APIManager.sharedInstance.login(completion: completedLogin)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case MainSegue:

            // Get the new view controller.
            let tabBarController = segue.destination as! UITabBarController
            let inventoryNavController = tabBarController.viewControllers![0] as! UINavigationController
            let controller = inventoryNavController.topViewController as! InventoryDateTVC
            print("SyncManager ...")
            _ = SyncManager(completionHandler: controller.completedLogin)
        case SignUpSegue:
            print("b")
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

            // A
            // Use prepare(for, sender) to init SyncManager with InventoryDateTVC.completedLogin
            // as completion handler
            //performSegue(withIdentifier: MainSegue, sender: self)

            // B
            _ = SyncManager(completionHandler: completedSync)

        } else {
            // TODO - how best to handle this?
            HUD.flash(.error, delay: 1.0); return
                print("Failed to login")
        }
    }

    // func completedSignup(json: JSON?, error: Error?) -> Void {}

    func completedSync(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            //performSegue(withIdentifier: InventorySegue, sender: self)
            performSegue(withIdentifier: MainSegue, sender: self)
        } else {
            HUD.flash(.error, delay: 1.0); return
        }
    }

}
