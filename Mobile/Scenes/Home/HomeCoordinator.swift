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
        var viewController = HomeViewController.initFromStoryboard(name: "Main")

        var avm: Attachable<HomeViewModel> = .detached(HomeViewModel.Dependency(dataManager: dataManager))
        viewController.bindViewModel(to: &avm)
        navigationController.viewControllers = [viewController]

        viewController.settingsButtonItem.rx.tap
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showSettings(on: viewController)
            }
            .subscribe()
            .disposed(by: disposeBag)

        // Navigation
        viewController.viewModel.showInventory
            .flatMap { [weak self] inventory -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showNewInventory(with: inventory)
            }
            .subscribe()
            .disposed(by: disposeBag)

        viewController.viewModel.showOrder
            .flatMap { [weak self] orderCollection -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showNewOrder(with: orderCollection)
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    private func showSettings(on rootViewController: UIViewController) -> Observable<Void> {
        let settingsCoordinator = SettingsCoordinator(rootViewController: rootViewController, dataManager: dataManager)
        return coordinate(to: settingsCoordinator)
    }

    public func showNewInventory(with inventory: Inventory) -> Observable<Void> {
        let newInventoryCoordinator = ModalInventoryCoordinator(rootViewController: navigationController,
                                                                dataManager: dataManager, inventory: inventory)
        return coordinate(to: newInventoryCoordinator)
    }

    private func showNewOrder(with collection: OrderCollection) -> Observable<Void> {
        let newOrderCoordinator = ModalOrderCoordinator(rootViewController: navigationController,
                                                        dataManager: dataManager, collection: collection)
        return coordinate(to: newOrderCoordinator)
    }

}
