//
//  InitialSignUpViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit
import KeychainAccess
import PKHUD
//import RxCocoa
//import RxSwift
import SwiftyJSON

class InitialSignUpViewController: UIViewController, SegueHandler {

    // NEW
    /// TODO: move this to view model
    var dataManager: DataManager!
    //var viewModel: InitialSignupViewModel!

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

    // override func didReceiveMemoryWarning() {}

    // MARK: - User interaction

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func signupButtonPressed(_ sender: AnyObject) {
        guard
            let username = usernameTextField.text,
            let email = loginTextField.text,
            let pass = passwordTextField.text
        else {
            return
        }
        HUD.show(.progress)
        userManager.signUp(username: username, email: email, password: pass, completion: completedSignup)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showMain:
            guard
                let tabBarController = segue.destination as? UITabBarController,
                let inventoryNavController = tabBarController.viewControllers![0] as? UINavigationController,
                let controller = inventoryNavController.topViewController as? InventoryDateViewController
            else {
                fatalError("Wrong view controller type")
            }
            let viewModel = InventoryDateViewModel(dataManager: dataManager,
                                                   rowTaps: controller.selectedObjects.asObservable())

            controller.viewModel = viewModel

            // Sync with completion handler from the new view controller.
            //_ = SyncManager(context: managedObjectContext, storeID: userManager.storeID!,
            //                completionHandler: controller.completedSync)
        case .showSignUp:
            log.verbose("SignUpSegue")

            // ...

            //controller.managedObjectContext = managedObjectContext
            //controller.userManager = userManager
        }
    }

}

// MARK: - UITextFieldDelegate
extension InitialSignUpViewController: UITextFieldDelegate {

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

}

// MARK: - Completion Handlers
extension InitialSignUpViewController {

    func completedSignup(error: BackendError?) {
        guard error == nil else {
            log.error("\(#function) FAILED: unable to sign up")
            HUD.flash(.error, delay: 1.0); return
        }
        log.verbose("Signed up")
        performSegue(withIdentifier: .showMain)
    }

}
