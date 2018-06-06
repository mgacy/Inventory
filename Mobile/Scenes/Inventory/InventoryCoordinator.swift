//
//  InventoryCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class InventoryCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    fileprivate let navigationController: UINavigationController
    fileprivate let dependencies: Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        let viewController = InventoryDateViewController.instance()
        let viewModel = InventoryDateViewModel(dataManager: dependencies.dataManager,
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

    fileprivate func showReviewList(with inventory: Inventory) {
        let viewController = InventoryReviewViewController.instance()
        let viewModel = InventoryReviewViewModel(dataManager: dependencies.dataManager, parentObject: inventory,
                                                 rowTaps: viewController.selectedObjects)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection?
    }

    fileprivate func showLocationList(with inventory: Inventory) {
        let viewController = InventoryLocationViewController.instance()
        let avm: Attachable<InventoryLocationViewModel> = .detached(InventoryLocationViewModel.Dependency(
            dataManager: dependencies.dataManager,
            parentObject: inventory
        ))
        let viewModel = viewController.attach(wrapper: avm)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        /// TODO: shouldn't this only take one and then complete?
        viewModel.showLocation
            //.take(1)
            .subscribe(onNext: { [weak self] selection in
                switch selection {
                case .category(let location):
                    self?.showCategoryList(with: location)
                case .item(let location):
                    self?.showLocationItemList(with: .location(location))
                }
            })
            .disposed(by: disposeBag)

        // Dismiss
        viewController.dismissView
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showCategoryList(with location: InventoryLocation) {
        let viewController = InventoryLocCatViewController.instance()
        viewController.viewModel = InventoryLocCatViewModel(dataManager: dependencies.dataManager,
                                                            parentObject: location)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewController.selectedObjects
            .subscribe(onNext: { [weak self] selection in
                self?.showLocationItemList(with: LocationItemListParent.category(selection))
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showLocationItemList(with parent: LocationItemListParent) {
        let viewController = InventoryLocItemViewController.instance()
        viewController.viewModel = InventoryLocItemViewModel(dataManager: dependencies.dataManager,
                                                             parentObject: parent)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewController.tableView.rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.showKeypad(for: parent, atIndex: indexPath.row)
            })
            .disposed(by: disposeBag)

        // Selection
        let itemSelection = viewController.tableView.rx
            .itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                //log.debug("We selected: \(indexPath)")
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showModalKeypad(for: parent, atIndex: indexPath.row)
            }
            .do(onNext: { _ in
                // Deselect
                if let selectedRowIndexPath = viewController.tableView.indexPathForSelectedRow {
                    viewController.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })

        itemSelection
            //.debug("itemSelection (from Coordinator")
            .subscribe()
            .disposed(by: viewController.disposeBag)
    }

    fileprivate func showKeypad(for parent: LocationItemListParent, atIndex index: Int) {
        let viewController = InventoryKeypadViewController()
        let viewModel = InventoryKeypadViewModel(dataManager: dependencies.dataManager, for: parent, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)
    }

    fileprivate func showModalKeypad(for parent: LocationItemListParent, atIndex index: Int) -> Observable<Void> {
        let keypadCoordinator = InventoryKeypadCoordinator(rootViewController: navigationController,
                                                           dependencies: dependencies, parent: parent, atIndex: index)
        return coordinate(to: keypadCoordinator)
    }

}

// MARK: - Modal Display from Home

class ModalInventoryCoordinator: InventoryCoordinator {

    private let rootViewController: UIViewController
    private let inventory: Inventory

    init(rootViewController: UIViewController, dependencies: Dependencies, inventory: Inventory) {
        self.rootViewController = rootViewController
        self.inventory = inventory
        super.init(navigationController: UINavigationController(), dependencies: dependencies)
    }

    override func start() -> Observable<Void> {
        let viewController = InventoryLocationViewController.initFromStoryboard(name: "InventoryLocationViewController")
        let avm: Attachable<InventoryLocationViewModel> = .detached(InventoryLocationViewModel.Dependency(
            dataManager: dependencies.dataManager,
            parentObject: inventory
        ))
        let viewModel = viewController.attach(wrapper: avm)

        navigationController.viewControllers = [viewController]
        rootViewController.present(navigationController, animated: true)

        // Selection
        viewModel.showLocation
            //.take(1)
            .subscribe(onNext: { [weak self] selection in
                switch selection {
                case .category(let location):
                    self?.showCategoryList(with: location)
                case .item(let location):
                    self?.showLocationItemList(with: .location(location))
                }
            })
            .disposed(by: disposeBag)

        // Dismiss
        return Observable.merge(
                viewController.cancelButtonItem.rx.tap.asObservable(),
                viewController.dismissView
            )
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

    override func showKeypad(for parent: LocationItemListParent, atIndex index: Int) {
        let viewController = InventoryKeypadViewController()
        let viewModel = InventoryKeypadViewModel(dataManager: dependencies.dataManager, for: parent, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

}
