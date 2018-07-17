//
//  InventoryKeypadCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/29/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift
import RxCocoa

final class InventoryKeypadCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let rootViewController: UIViewController
    private let dependencies: Dependencies
    private let parent: LocationItemListParent
    private let index: Int

    init(rootViewController: UIViewController, dependencies: Dependencies, parent: LocationItemListParent, atIndex index: Int) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
        self.parent = parent
        self.index = index
    }

    override func start() -> Observable<Void> {
        let viewController = InventoryKeypadViewController()
        let viewModel = InventoryKeypadViewModel(dataManager: dependencies.dataManager, for: parent, atIndex: index)
        viewController.viewModel = viewModel

        let presentedViewController: UIViewController & ModalKeypadDismissing
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            presentedViewController = viewController
        case .pad:
            /// TODO: use rootViewController dimensions to configure modalViewController constraints
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
