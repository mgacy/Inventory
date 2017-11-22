//
//  InitialLoginViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import OnePasswordExtension
import PKHUD
import RxCocoa
import RxSwift

class InitialLoginViewController: UIViewController, SegueHandler {

    private enum Strings {
        static let errorAlertTitle = "Error"
        static let loginErrorMessage = "Wrong email or password"
    }

    // MARK: Properties

    var viewModel: InitialLoginViewModel!
    let disposeBag = DisposeBag()

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
        setupView()
        //setupConstraints()
        setupBindings()

        if let user = viewModel.currentUser {
            loginTextField.text = user.email
        }
    }

    // override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        /// TODO: enable signup
        signupButton.isEnabled = false

        loginTextField.delegate = self
        passwordTextField.delegate = self

        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            setupTextFieldFor1Password()
        }
    }

    //private func setupConstraints() {}

    // swiftlint:disable:next function_body_length
    private func setupBindings() {
        loginTextField.rx.text
            .orEmpty
            .bind(to: viewModel.username)
            .disposed(by: disposeBag)

        loginTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { _ in
                self.passwordTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)

        passwordTextField.rx.text
            .orEmpty
            .bind(to: viewModel.password)
            .disposed(by: disposeBag)
        /*
        passwordTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { _ in
                 /// TODO: event to make viewModel login
            })
            .disposed(by: disposeBag)
        */
        loginButton.rx.tap
            .bind(to: viewModel.loginTaps)
            .disposed(by: disposeBag)

        signupButton.rx.tap
            .bind(to: viewModel.signupTaps)
            .disposed(by: disposeBag)

        // from the viewModel

        viewModel.isValid
            .map { $0 }
            .bind(to: loginButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.loggingIn
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        viewModel.loginResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    log.verbose("Logged in")
                    HUD.flash(.success, delay: 0.2) { _ in
                        /// TODO: handle this elsewhere
                        self?.performSegue(withIdentifier: .showMain)
                    }
                case .error(let error):
                    switch error as? BackendError {
                    case .authentication?:
                        UIViewController.showErrorInHUD(title: Strings.errorAlertTitle,
                                                        subtitle: Strings.loginErrorMessage)
                    default:
                        HUD.flash(.error, delay: 1.0)
                    }
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showMain:

            // swiftlint:disable:next force_cast
            let appDelegate = UIApplication.shared.delegate! as! AppDelegate
            let tabBarController = appDelegate.prepareTabBarController(dataManager: appDelegate.dataManager)
            appDelegate.window?.rootViewController = tabBarController

        case .showSignUp:
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? InitialSignUpViewController
                else {
                    fatalError("\(#function) FAILED : unable to get destination")
            }
            destinationController.viewModel = InitialSignUpViewModel(dataManager: viewModel.dataManager)
        }
    }

}

// MARK: - UITextFieldDelegate
extension InitialLoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /*
        switch textField {
        case loginTextField:
            log.debug("A")
            /// TODO: perform validation
        case passwordTextField:
            log.debug("B")
            /// TODO: perform validation
        default:
            log.debug("C")
            //textField.resignFirstResponder()
        }
        */
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
extension InitialLoginViewController {

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
