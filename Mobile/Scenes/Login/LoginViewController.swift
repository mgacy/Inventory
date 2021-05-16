//
//  LoginViewController.swift
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

class LoginViewController: UIViewController {

    private enum Strings {
        static let errorAlertTitle = "Error"
        static let loginErrorMessage = "Wrong email or password"
    }

    // MARK: Properties

    private typealias Input = LoginViewModel.Input
    var viewModel: LoginViewModel!
    let disposeBag = DisposeBag()

    fileprivate let _didLogin = PublishSubject<Void>()
    let didLogin: Observable<Void>

    // MARK: Interface
    let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: nil)

    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        self.didLogin = _didLogin.asObservable()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
        bindViewModel()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        //signupButton.isEnabled = false

        loginTextField.delegate = self
        passwordTextField.delegate = self

        // FIXME: should I disable this check?
        if self.presentingViewController != nil {
            // We are being presented from settings (or somewhere else within rather than during startup)
            /// TODO: should we hide the 'Sign Up' button?
            self.navigationItem.leftBarButtonItem = cancelButtonItem
        }

        if OnePasswordExtension.shared().isAppExtensionAvailable() {
            setupTextFieldFor1Password()
        }
    }

    //private func setupConstraints() {}

    // swiftlint:disable:next function_body_length
    private func bindViewModel() {
        let inputs = Input(
            username: loginTextField.rx.text.orEmpty.asObservable(),
            password: passwordTextField.rx.text.orEmpty.asObservable(),
            loginTaps: loginButton.rx.tap.asObservable(),
            doneTaps: passwordTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
        let outputs = viewModel.transform(input: inputs)

        outputs.currentUser
            .flatMap { $0 == nil ? Observable.empty() : Observable.just($0!) }
            .map { return $0.email }
            .subscribe(onNext: { [weak self] email in
                self?.loginTextField.text = email
            })
            .disposed(by: disposeBag)

        outputs.isValid
            .map { $0 }
            .bind(to: loginButton.rx.isEnabled)
            .disposed(by: disposeBag)

        outputs.loggingIn
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        outputs.loginResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    log.verbose("Logged in")
                    HUD.flash(.success, delay: 0.2) { _ in
                        self?._didLogin.onNext(())
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

        // Next keyboard button
        loginTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { _ in
                self.passwordTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {

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
extension LoginViewController {

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
                        log.error("Error invoking 1Password App Extension for find login: \(String(describing: error))")
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
