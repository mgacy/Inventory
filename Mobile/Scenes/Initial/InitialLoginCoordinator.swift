//
//  InitialLoginCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InitialLoginCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow
    private let dataManager: DataManager

    init(window: UIWindow, dataManager: DataManager) {
        self.window = window
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        let viewController = InitialLoginViewController.initFromStoryboard(name: "Main")
        let viewModel = InitialLoginViewModel(dataManager: dataManager)
        viewController.viewModel = viewModel

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        viewController.didLogin
            .subscribe(onNext: { [weak self] _ in
                log.debug("We should showMain")
                self?.showMain()
            })
            .disposed(by: disposeBag)

        viewController.signupButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                log.debug("Tapped signupButton")
                self?.showSignup(from: viewController)
            })
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    private func showMain() {
        log.debug("\(#function)")
    }

    private func showSignup(from presentingViewController: UIViewController) {
        log.debug("\(#function)")
        let viewController = InitialSignUpViewController.initFromStoryboard(name: "Main")
        let viewModel = InitialSignUpViewModel(dataManager: dataManager)
        viewController.viewModel = viewModel

        let navigationController = UINavigationController(rootViewController: viewController)
        presentingViewController.present(navigationController, animated: true, completion: nil)

        // cancelButton
        viewController.cancelButton.rx.tap
            .subscribe(onNext: { _ in
                log.debug("Dismissing ...")
                viewController.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        // didSignup

    }

}
