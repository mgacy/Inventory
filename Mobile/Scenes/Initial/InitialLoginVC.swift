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

class InitialLoginVC: UIViewController, RootSectionViewController, SegueHandler {

    // MARK: Properties
    var managedObjectContext: NSManagedObjectContext!
    var userManager: CurrentUserManager!

    // MARK: Interface
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    // Segue
    enum SegueIdentifier: String {
        //case showInventories = "showInventories"
        //case showOrders = "showOrders"
        //case showInvoices = "showInvoices"
        //case showSettings = "showSettings"
        case showMain = "showTabController"
        case showSignUp = "showSignUpController"
    }

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showMain:

            // swiftlint:disable:next force_cast
            let appDelegate = UIApplication.shared.delegate! as! AppDelegate
            appDelegate.prepareTabBarController()

        case .showSignUp:
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? InitialSignUpViewController
                else {
                    fatalError("\(#function) FAILED : unable to get destination")
            }
            destinationController.managedObjectContext = managedObjectContext
            destinationController.userManager = userManager
        }
    }

}

// MARK: - UITextFieldDelegate
extension InitialLoginVC: UITextFieldDelegate {

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
extension InitialLoginVC {

    func completedLogin(_ error: BackendError? = nil) {
        guard error == nil else {
            log.error("Failed to login: \(String(describing: error))")
            switch error! {
            case .authentication:
                showError(title: "Error", subtitle: "Wrong email or password")
            default:
                HUD.flash(.error, delay: 1.0)
            }
            return
        }
        log.verbose("Logged in")
        // TODO: change so we only createUser() on success
        performSegue(withIdentifier: .showMain)
    }

}

/// TODO: make extension of PKHUD
extension InitialLoginVC {

    func showError(title: String, subtitle: String?, delay: Double = 2.0) {
        PKHUD.sharedHUD.show()
        PKHUD.sharedHUD.contentView = PKHUDErrorView(title: title, subtitle: subtitle)
        PKHUD.sharedHUD.hide(afterDelay: delay)
    }

}
