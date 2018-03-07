//
//  HomeCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class HomeCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager & HasUserManager

    private let navigationController: UINavigationController
    private let dependencies: Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        var viewController = HomeViewController.instance()

        var avm: Attachable<HomeViewModel> = .detached(dependencies)
        //let viewModel = viewController.bindViewModel(to: &avm)
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

        viewController.viewModel.transition
            .asObservable()
            .subscribe(onNext: { transition in
                log.warning("We should transition to: \(transition)")
            })
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    private func showSettings(on rootViewController: UIViewController) -> Observable<Void> {
        let settingsCoordinator = SettingsCoordinator(rootViewController: rootViewController,
                                                      dependencies: dependencies)
        return coordinate(to: settingsCoordinator)
    }

    public func showNewInventory(with inventory: Inventory) -> Observable<Void> {
        let newInventoryCoordinator = ModalInventoryCoordinator(rootViewController: navigationController,
                                                                dependencies: dependencies, inventory: inventory)
        return coordinate(to: newInventoryCoordinator)
    }

    private func showNewOrder(with collection: OrderCollection) -> Observable<Void> {
        let newOrderCoordinator = ModalOrderCoordinator(rootViewController: navigationController,
                                                        dependencies: dependencies, collection: collection)
        return coordinate(to: newOrderCoordinator)
    }

}
