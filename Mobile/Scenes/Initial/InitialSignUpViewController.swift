//
//  InitialSignUpViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/26/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit
import PKHUD
import RxCocoa
import RxSwift

class InitialSignUpViewController: UIViewController, SegueHandler {

    enum Strings {
        static let navTitle = "Signup"
        static let errorAlertTitle = "Error"
    }

    // MARK: Properties

    /// TODO: move this to view model
    //var dataManager: DataManager!
    var viewModel: InitialSignUpViewModel!
    let disposeBag = DisposeBag()

    // Segue
    enum SegueIdentifier: String {
        case showMain = "showTabController"
        //case showInventories = "showInventories"
        //case showLogin = "showLogin"
    }

    // MARK: Interface
    //private let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: nil)

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        //setupView()
        //setupConstraints()
        setupBindings()
    }

    // override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        //self.navigationItem.leftBarButtonItem = cancelButton
    }

    // private func setupConstraints() {}

    private func setupBindings() {
        usernameTextField.rx.text
            .orEmpty
            .bind(to: viewModel.username)
            .disposed(by: disposeBag)

        loginTextField.rx.text
            .orEmpty
            .bind(to: viewModel.login)
            .disposed(by: disposeBag)

        passwordTextField.rx.text
            .orEmpty
            .bind(to: viewModel.password)
            .disposed(by: disposeBag)
        /*
        cancelButton.rx.tap
            //.bind(to: viewModel.cancel)
            .subscribe(onNext: {
                dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        */
        signupButton.rx.tap
            .bind(to: viewModel.signupTaps)
            .disposed(by: disposeBag)

        // from the viewModel
        viewModel.isValid.map { $0 }
            .bind(to: signupButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.signingUp
            .filter { $0 }
            .drive(onNext: { _ in
                HUD.show(.progress)
            })
            .disposed(by: disposeBag)

        viewModel.signupResults
            .subscribe(onNext: { [weak self] result in
                switch result.event {
                case .next:
                    HUD.flash(.success, delay: 1.0) { _ in
                        /// TODO: handle this elsewhere
                        /// TODO: replace use of segues
                        self?.performSegue(withIdentifier: .showMain)
                        //self?.navigationController!.popViewController(animated: true)
                    }
                case .error:
                    /// TODO: `case.error(let error):; switch error {}`
                    UIViewController.showErrorInHUD(title: Strings.errorAlertTitle, subtitle: "Message")
                case .completed:
                    log.warning("\(#function) : not sure how to handle completion")
                }
            })
            .disposed(by: disposeBag)

    }

    // MARK: - User interaction

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
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
            controller.viewModel = InventoryDateViewModel(dataManager: viewModel.dataManager,
                                                          rowTaps: controller.selectedObjects.asObservable())

            // Sync with completion handler from the new view controller.
            //_ = SyncManager(context: managedObjectContext, storeID: userManager.storeID!,
            //                completionHandler: controller.completedSync)
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
        // Disable the SignUp button while editing.
        signupButton.isEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // checkValidMealName()
    }

}
