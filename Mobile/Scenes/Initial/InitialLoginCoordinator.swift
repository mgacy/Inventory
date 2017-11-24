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

    override func start() -> Observable<CoordinationResult> {
        let viewController = InitialLoginViewController.initFromStoryboard(name: "Main")
        let viewModel = InitialLoginViewModel(dataManager: dataManager)
        viewController.viewModel = viewModel

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        let signedUp = viewController.signupButton.rx.tap
            .flatMap { _ -> Observable<SignupCoordinationResult> in
                return self.showSignup(on: viewController)
            }
            .filter { $0 != SignupCoordinationResult.cancel }
            .map { _ in return }

        return Observable.merge(viewController.didLogin, signedUp)
            .take(1)
            //.do(onNext: { log.debug("\(#function)") })
    }

    // MARK: - Sections

    private func showSignup(on rootViewController: UIViewController) -> Observable<SignupCoordinationResult> {
        let signupCoordinator = SignupCoordinator(rootViewController: rootViewController, dataManager: self.dataManager)
        return coordinate(to: signupCoordinator)
            //.filter { $0 != .cancel }
    }

}
