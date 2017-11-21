//
//  HomeCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class HomeCoordinator: BaseCoordinator<Void> {

    private let navigationController: UINavigationController
    private let dataManager: DataManager

    init(navigationController: UINavigationController, dataManager: DataManager) {
        self.navigationController = navigationController
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        log.debug("\(#function)")
        let viewController = HomeViewController.initFromStoryboard(name: "Main")
        let viewModel = HomeViewModel(dataManager: dataManager)
        viewController.viewModel = viewModel

        navigationController.viewControllers = [viewController]

        return Observable.never()
    }

    // MARK: - Sections

}
