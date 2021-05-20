//
//  OrderKeypadCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/18/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift
import RxCocoa

final class OrderKeypadCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = OrderKeypadViewModel.Dependency

    private let rootViewController: UIViewController
    private let dependencies: Dependencies

    init(rootViewController: UIViewController, dependencies: Dependencies) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        let viewController = OrderKeypadViewController()
        let viewModel = OrderKeypadViewModel(dependency: dependencies)
        viewController.viewModel = viewModel

        let presentedViewController: UIViewController & ModalKeypadDismissing
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            presentedViewController = viewController
        case .pad:
            // TODO: use rootViewController dimensions to configure modalViewController constraints
            presentedViewController = ModalKeypadViewController(keypadViewController: viewController)
        default:
            fatalError("Unable to setup bindings for unrecognized device: \(UIDevice.current.userInterfaceIdiom)")
        }

        rootViewController.present(presentedViewController, animated: true)
        return presentedViewController.dismissalEvents
            .debug("KeypadCoordinator: dismissalEvents")
            .take(1)
            .do(onNext: { [weak self] dismissalEvent in
                if case .shouldDismiss = dismissalEvent {
                    self?.rootViewController.dismiss(animated: true)
                }
            })
            .mapToVoid()
    }

}
