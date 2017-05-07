//
//  InitialLoginVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit
import KeychainAccess
import PKHUD
//import SwiftyJSON

class InitialLoginVC: UIViewController, UITextFieldDelegate, RootSectionViewController, SegueHandler {

    // MARK: Properties
    var managedObjectContext: NSManagedObjectContext!
    var userManager: CurrentUserManager!

    // Segue
    enum SegueIdentifier: String {
        //case showInventories = "showInventories"
        //case showOrders = "showOrders"
        //case showInvoices = "showInvoices"
        //case showSettings = "showSettings"
        case showMain = "showTabController"
        case showSignUp = "showSignUpController"
    }

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

    //@IBAction func signupButtonPressed(_ sender: AnyObject) {}

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
            _ = SyncManager(context: managedObjectContext, storeID: userManager.storeID!,
                            completionHandler: controller.completedSync)
        case .showSignUp:

            // Get the new view controller.
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? InitialSignUpVC
                else {
                    fatalError("\(#function) FAILED : unable to get destination")
            }

            // Pass dependencies to the new view controller.
            destinationController.managedObjectContext = managedObjectContext
            destinationController.userManager = userManager
        }
    }

}

// MARK: - Completion Handlers
extension InitialLoginVC {

    func completedLogin(success: Bool) {
        if success {
            log.verbose("Logged in")
            // TODO: change so we only createUser() on success
            performSegue(withIdentifier: .showMain)
        } else {
            log.error("\(#function) FAILED: unable to login")
            userManager.removeUser()
            /// TODO: how best to handle this?
            HUD.flash(.error, delay: 1.0); return
        }
    }

}
