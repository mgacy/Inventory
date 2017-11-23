//
//  SignupCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/22/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

enum SignupCoordinationResult {
    case signedUp
    case cancel
}

class SignupCoordinator: BaseCoordinator<SignupCoordinationResult> {

    private let rootViewController: UIViewController
    private let dataManager: DataManager

    init(rootViewController: UIViewController, dataManager: DataManager) {
        self.rootViewController = rootViewController
        self.dataManager = dataManager
    }

    override func start() -> Observable<CoordinationResult> {
        //log.debug("\(#function)")
        let viewController = InitialSignUpViewController.initFromStoryboard(name: "Main")
        let navigationController = UINavigationController(rootViewController: viewController)

        let viewModel = InitialSignUpViewModel(dataManager: dataManager)
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
