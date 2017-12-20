//
//  SignUpViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class SignUpViewController: UIViewController {

    enum Strings {
        static let navTitle = "Signup"
        static let errorAlertTitle = "Error"
        static let signupErrorMessage = "There was a problem"
    }

    // MARK: Properties

    private typealias Input = SignUpViewModel.Input
    var viewModel: SignUpViewModel!
    let disposeBag = DisposeBag()

    fileprivate let _didSignup = PublishSubject<Void>()
    let didSignup: Observable<Void>

    // MARK: Interface
    let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: nil)

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!

    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        self.didSignup = _didSignup.asObservable()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        //setupConstraints()
        bindViewModel()
    }

    // override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        self.navigationItem.leftBarButtonItem = cancelButton
        usernameTextField.delegate = self
        loginTextField.delegate = self
        passwordTextField.delegate = self
    }

    // private func setupConstraints() {}

    // swiftlint:disable:next function_body_length
    private func bindViewModel() {
        let inputs = Input(
            username: usernameTextField.rx.text.orEmpty.asObservable(),
            login: loginTextField.rx.text.orEmpty.asObservable(),
            password: passwordTextField.rx.text.orEmpty.asObservable(),
            signupTaps: signupButton.rx.tap.asObservable(),
            doneTaps: passwordTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
        let outputs = viewModel.transform(input: inputs)

        outputs.isValid
            .map { $0 }
            .bind(to: signupButton.rx.isEnabled)
            .disposed(by: disposeBag)

        outputs.signingUp
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        outputs.signupResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    log.verbose("Logged in")
                    HUD.flash(.success, delay: 0.2) { _ in
                        self?._didSignup.onNext(())
                    }
                case .error(let error):
                    switch error as? BackendError {
                    case .authentication?:
                        UIViewController.showErrorInHUD(title: Strings.errorAlertTitle,
                                                        subtitle: Strings.signupErrorMessage)
                    default:
                        HUD.flash(.error, delay: 1.0)
                    }
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)

        // Next keyboard button
        usernameTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { _ in
                self.loginTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)

        loginTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { _ in
                self.passwordTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - UITextFieldDelegate
extension SignUpViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    /*
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the SignUp button while editing.
        signupButton.isEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
    }
    */
}
