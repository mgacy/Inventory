//
//  ItemCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class ItemCoordinator: BaseCoordinator<Void> {

    private let navigationController: UINavigationController
    private let dataManager: DataManager

    init(navigationController: UINavigationController, dataManager: DataManager) {
        self.navigationController = navigationController
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        log.debug("\(#function)")
        let viewController = ItemViewController.initFromStoryboard(name: "Main")
        let viewModel = ItemViewModel(dataManager: dataManager,
                                      rowTaps: viewController.rowTaps.asObservable())
        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selction
        // ...

        return Observable.never()
    }

    // MARK: - Sections

    //private func showItemDetail(item: Item) {}

}
