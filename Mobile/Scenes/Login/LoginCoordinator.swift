//
//  LoginCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InitialLoginCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager & HasUserManager

    private let window: UIWindow
    private let dependencies: Dependencies

    init(window: UIWindow, dependencies: Dependencies) {
        self.window = window
        self.dependencies = dependencies
    }

    override func start() -> Observable<CoordinationResult> {
        let viewController = LoginViewController.instance()
        let viewModel = LoginViewModel(dataManager: dependencies.dataManager)
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
        let signupCoordinator = SignupCoordinator(rootViewController: rootViewController, dependencies: dependencies)
        return coordinate(to: signupCoordinator)
            //.filter { $0 != .cancel }
    }

}

// MARK: - Alt
/*
enum CoordinatorMode {
    case root(UIWindow)
    case section(UINavigationController)
    case modal(UIViewController)
}
*/
class LoginCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let window: UIWindow?
    private let rootViewController: UIViewController?
    private let dependencies: Dependencies

    init(window: UIWindow, dependencies: Dependencies) {
        self.window = window
        self.rootViewController = nil
        self.dependencies = dependencies
    }

    init(rootViewController: UIViewController, dependencies: Dependencies) {
        self.window = nil
        self.rootViewController = rootViewController
        self.dependencies = dependencies
    }

    override func start() -> Observable<CoordinationResult> {
        let viewController = LoginViewController.instance()
        let viewModel = LoginViewModel(dataManager: dependencies.dataManager)
        viewController.viewModel = viewModel

        if let `window` = window {
            // Display as initial window
            log.debug("\(#function) : display as root view controller of: \(window)")
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

        } else {
            // Display in NavigationController
            log.debug("\(#function) : display in navigation controller")
            guard let rootViewController = rootViewController else {
                fatalError("\(#function) FAILED : unable to get expected root view controller")
            }

            let cancelled = viewController.cancelButtonItem.rx.tap.asObservable()
            /*
            let signedUp = viewController.signupButton.rx.tap
                .flatMap { _ -> Observable<SignupCoordinationResult> in
                    return self.showSignup(on: viewController)
                }
                .filter { $0 != SignupCoordinationResult.cancel }
                .map { _ in return }
            */

            let navigationController = UINavigationController(rootViewController: viewController)
            rootViewController.present(navigationController, animated: true)

            return Observable.merge(viewController.didLogin, cancelled)
                .take(1)
                .do(onNext: { _ in rootViewController.dismiss(animated: true) })
        }
    }

    // MARK: - Sections

    private func showSignup(on rootViewController: UIViewController) -> Observable<SignupCoordinationResult> {
        let signupCoordinator = SignupCoordinator(rootViewController: rootViewController, dependencies: dependencies)
        return coordinate(to: signupCoordinator)
        //.filter { $0 != .cancel }
    }

}
