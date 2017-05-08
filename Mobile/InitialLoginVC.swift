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

            // swiftlint:disable:next force_cast
            let appDelegate = UIApplication.shared.delegate! as! AppDelegate
            appDelegate.prepareTabBarController()

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

    func completedLogin(_ error: BackendError? = nil) {
        guard error == nil else {
            log.error("Failed to login")
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
