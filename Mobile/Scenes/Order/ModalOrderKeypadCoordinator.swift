//
//  ModalOrderKeypadCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/18/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import RxSwift
import RxCocoa

class ModalOrderKeypadCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let rootViewController: UIViewController
    private let dependencies: Dependencies
    private let orderItems: [OrderItem]
    private let index: Int

    init(rootViewController: UIViewController, dependencies: Dependencies, orderItems: [OrderItem], atIndex index: Int) {
        self.rootViewController = rootViewController
        self.dependencies = dependencies
        self.orderItems = orderItems
        self.index = index
    }

    override func start() -> Observable<Void> {
        let viewController = OrderKeypadViewController.instance()
        let viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, with: orderItems, atIndex: index)
        viewController.viewModel = viewModel

        /// TODO: use rootViewController dimensions to configure modalViewController constraints
        let modalViewController = ModalOrderKeypadViewController(keypadViewController: viewController)
        rootViewController.present(modalViewController, animated: true)

        return modalViewController.dismissalEvents
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
