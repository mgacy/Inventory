//
//  ModalOrderKeypadCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/18/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift
import RxCocoa

final class ModalOrderKeypadCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    enum OrderDisplayType {
        case location([OrderItem])
        case vendor(Order)
    }

    private let rootViewController: UIViewController
    private let dependencies: Dependencies
    private let displayType: OrderDisplayType
    private let index: Int

    init(rootViewController: UIViewController, dependencies: Dependencies, orderItems: [OrderItem], atIndex index: Int) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
        self.displayType = .location(orderItems)
        self.index = index
    }

    init(rootViewController: UIViewController, dependencies: Dependencies, order: Order, atIndex index: Int) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
        self.displayType = .vendor(order)
        self.index = index
    }

    override func start() -> Observable<Void> {
        let viewController = OrderKeypadViewController.instance()
        let viewModel: OrderKeypadViewModel
        switch displayType {
        case .location(let orderItems):
            viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, with: orderItems, atIndex: index)
        case .vendor(let order):
            viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, for: order, atIndex: index)
        }
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
            .debug()
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
