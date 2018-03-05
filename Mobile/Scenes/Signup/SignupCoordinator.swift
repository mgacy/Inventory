//
//  SignupCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/22/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

/// Type defining possible coordination results of the `SignupCoordinator`.
///
/// - signUp: Signup completed successfully.
/// - cancel: Cancel button was tapped.
enum SignupCoordinationResult {
    case signedUp
    case cancel
}

class SignupCoordinator: BaseCoordinator<SignupCoordinationResult> {
    typealias Dependencies = HasDataManager

    private let rootViewController: UIViewController
    private let dependencies: Dependencies

    init(rootViewController: UIViewController, dependencies: Dependencies) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
    }

    override func start() -> Observable<CoordinationResult> {
        let viewController = SignUpViewController.instance()
        let navigationController = UINavigationController(rootViewController: viewController)

        let viewModel = SignUpViewModel(dataManager: dependencies.dataManager)
        viewController.viewModel = viewModel

        let cancel = viewController.cancelButton.rx.tap
            .map { _ in CoordinationResult.cancel }

        let signedUp = viewController.didSignup.asObservable()
            .map { _ in CoordinationResult.signedUp }

        rootViewController.present(navigationController, animated: true)

        return Observable.merge(cancel, signedUp)
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
