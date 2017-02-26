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

            print("Destination: \(segue.destination)")

            // Get the new view controller.
            guard let tabController = segue.destination as? UITabBarController else {
                print("PROBLEM B")
                HUD.flash(.error, delay: 1.0); return
            }

            print("\(tabController)")
            print("\(tabController.selectedViewController)")
            print("\(tabController.selectedIndex)")
            print("\(tabController.viewControllers)")

            guard let controller = tabController.viewControllers?[0] as? InventoryDateTVC else {
                print("PROBLEM C")
                HUD.flash(.error, delay: 1.0); return
            }

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
            performSegue(withIdentifier: MainSegue, sender: self)
        } else {
            HUD.flash(.error, delay: 1.0); return
        }
    }

}
