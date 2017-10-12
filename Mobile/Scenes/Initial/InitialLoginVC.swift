//
//  InitialLoginVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit
import RxCocoa
import RxSwift
import KeychainAccess
import OnePasswordExtension
import PKHUD
//import SwiftyJSON

class InitialLoginVC: UIViewController, SegueHandler {

    // MARK: New

    var viewModel: InitialLoginViewModel!
    let disposeBag = DisposeBag()

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

        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            setupTextFieldFor1Password()
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
            appDelegate.prepareTabBarController(dataManager: appDelegate.dataManager!)

        case .showSignUp:
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? InitialSignUpViewController
                else {
                    fatalError("\(#function) FAILED : unable to get destination")
            }
            destinationController.dataManager = viewModel.dataManager
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

// MARK: - 1Password Integration
extension InitialLoginVC {

    func setupTextFieldFor1Password() {
        guard let onePasswordButton = OnePasswordExtension.shared().getButton(ofWidth: 20) else {
            return
        }
        onePasswordButton.addTarget(self, action: #selector(findLoginFrom1Password(sender:)), for: .touchUpInside)

        passwordTextField.addButton(button: onePasswordButton, direction: .right)
    }

    @objc func findLoginFrom1Password(sender: AnyObject) {
        OnePasswordExtension.shared().findLogin(
            forURLString: "***REMOVED***", for: self, sender: sender,
            completion: { (loginDictionary, error) -> Void in
                if loginDictionary == nil {
                    if error!._code == Int(AppExtensionErrorCodeCancelledByUser) {
                        print("Error invoking 1Password App Extension for find login: \(String(describing: error))")
                    }
                    return
                }
                self.loginTextField.text = loginDictionary?[AppExtensionUsernameKey] as? String
                self.passwordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String
                /*
                if let generatedOneTimePassword = loginDictionary?[AppExtensionTOTPKey] as? String {
                    self.passwordTextField.text = generatedOneTimePassword

                    // Important: It is recommended that you submit the OTP/TOTP to your validation server as soon as you receive it, otherwise it may expire.
                    let dispatchTime = DispatchTime.now() + 0.5
                    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                        self.performSegue(withIdentifier: "showThankYouViewController", sender: self)
                    })
                }
                */
        })
    }

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

// MARK: - 1Password Extension

extension OnePasswordExtension {

    /// TODO: add enum for different images
    // "onepassword-button.png"
    // "onepassword-button-light.png"

    func getButton(ofWidth width: Int) -> UIButton? {
        let onePasswordButton = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: width))
        onePasswordButton.contentMode = UIViewContentMode.center

        guard let path = Bundle(for: type(of: OnePasswordExtension.shared())).path(
            forResource: "OnePasswordExtensionResources", ofType: "bundle") as String? else {
                return nil
        }
        let onepasswordBundle = Bundle(path: path)
        let image = UIImage(named: "onepassword-button.png", in: onepasswordBundle, compatibleWith: nil)
        onePasswordButton.setImage(image, for: .normal)

        return onePasswordButton
    }

}
