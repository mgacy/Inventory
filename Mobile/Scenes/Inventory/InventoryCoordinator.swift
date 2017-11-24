//
//  InventoryCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InventoryCoordinator: BaseCoordinator<Void> {

    private let navigationController: UINavigationController
    private let dataManager: DataManager

    init(navigationController: UINavigationController, dataManager: DataManager) {
        self.navigationController = navigationController
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        let viewController = InventoryDateViewController.initFromStoryboard(name: "Main")

        let viewModel = InventoryDateViewModel(dataManager: dataManager,
                                               rowTaps: viewController.selectedObjects.asObservable())
        //let viewModel = InventoryDateViewModel2(dataManager: dataManager)

        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selection
        viewModel.showInventory
            .subscribe(onNext: { [weak self] transition in
                switch transition {
                case .existing(let inventory):
                    log.verbose("GET selectedInventory from server - \(inventory.remoteID) ...")
                    self?.showReviewList(with: inventory)
                case .new(let inventory):
                    log.verbose("LOAD NEW selectedInventory from disk ...")
                    self?.showLocationList(with: inventory)
                }
            })
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    func showReviewList(with inventory: Inventory) {
        let viewController = InventoryReviewViewController.initFromStoryboard(name: "InventoryReviewViewController")
        let viewModel = InventoryReviewViewModel(dataManager: dataManager, parentObject: inventory,
                                                 rowTaps: viewController.selectedObjects)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection?
    }

    func showLocationList(with inventory: Inventory) {
        let viewController = InventoryLocationViewController.initFromStoryboard(name: "InventoryLocationViewController")
        let viewModel = InventoryLocationViewModel(dataManager: dataManager, parentObject: inventory,
                                                   rowTaps: viewController.selectedIndices,
                                                   uploadTaps: viewController.uploadButtonItem.rx.tap.asObservable())
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        /// TODO: shouldn't this only take one and then complete?
        viewModel.showLocation
            .subscribe(onNext: { [weak self] selection in
                switch selection {
                case .category(let location):
                    self?.showCategoryList(with: location)
                case .item(let location):
                    self?.showLocationItemList(with: .location(location))
                }
            })
            .disposed(by: disposeBag)
    }

    func showCategoryList(with location: InventoryLocation) {
        let viewController = InventoryLocationCategoryTVC.initFromStoryboard(name: "Main")
        //guard let viewController = InventoryLocationCategoryTVC.instance() else {
        //    fatalError("Wrong view controller.")
        //}
        viewController.viewModel = InventoryLocCatViewModel(dataManager: dataManager, parentObject: location)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewController.selectedObjects
            .subscribe(onNext: { [weak self] selection in
                self?.showLocationItemList(with: LocationItemListParent.category(selection))
            })
            .disposed(by: disposeBag)
    }

    func showLocationItemList(with parent: LocationItemListParent) {
        let viewController = InventoryLocationItemTVC.initFromStoryboard(name: "Main")
        //guard let viewController = InventoryLocationItemTVC.instance() else {
        //    fatalError("Wrong view controller.")
        //}
        viewController.viewModel = InventoryLocItemViewModel(dataManager: dataManager, parentObject: parent)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewController.selectedIndices
            .subscribe(onNext: { [weak self] index in
                self?.showKeypad(for: parent, atIndex: index.row)
            })
            .disposed(by: disposeBag)
    }

    func showKeypad(for parent: LocationItemListParent, atIndex index: Int) {
        guard let viewController = InventoryKeypadViewController.instance() else {
            fatalError("Wrong view controller.")
        }
        let viewModel = InventoryKeypadViewModel(dataManager: dataManager, for: parent, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

}
