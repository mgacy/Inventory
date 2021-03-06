//
//  ItemCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class ItemCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    private let navigationController: UINavigationController
    private let dependencies: Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        let viewController = ItemViewController()
        let viewModel = ItemViewModel(dependency: dependencies, bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selction
        // ...

        return Observable.never()
    }

    // MARK: - Sections

    //private func showItemDetail(item: Item) {}

}
