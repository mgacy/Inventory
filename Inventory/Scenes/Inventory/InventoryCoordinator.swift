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
        let viewController = InventoryDateViewController()
        let viewModel = InventoryDateViewModel(dependency: dependencies, bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selection
        viewModel.showInventory
            .debug("itemSelection - InventoryDateVC")
            .subscribe(onNext: { [weak self] transition in
                switch transition {
                case .existing(let inventory):
                    //log.verbose("GET selectedInventory from server - \(inventory.remoteID) ...")
                    self?.showReviewList(with: inventory)
                case .new(let inventory):
                    //log.verbose("LOAD NEW selectedInventory from disk ...")
                    self?.showLocationList(with: inventory)
                }
            })
            .disposed(by: disposeBag)

//        // Selection (B)
//        viewModel.showInventory
//            .flatMap { [weak self] transition -> Observable<Void> in
//                guard let strongSelf = self else { return .empty() }
//                switch transition {
//                case .existing(let inventory):
//                    //log.verbose("GET selectedInventory from server - \(inventory.remoteID) ...")
//                    return strongSelf.showReviewList2(with: inventory)
//                case .new(let inventory):
//                    //log.verbose("LOAD NEW selectedInventory from disk ...")
//                    return strongSelf.showLocationList2(with: inventory)
//                }
//            }
//            .debug("itemSelection - InventoryDateVC")
//            .subscribe()
//            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    fileprivate func showReviewList(with inventory: Inventory) {
        let viewController = InventoryReviewViewController()
        let viewModel = InventoryReviewViewModel(
            dependency: InventoryReviewViewModel.Dependency(dataManager: dependencies.dataManager, parent: inventory),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection?
    }

    fileprivate func showLocationList(with inventory: Inventory) {
        let viewController = InventoryLocationViewController()
        let avm: Attachable<InventoryLocationViewModel> = .detached(InventoryLocationViewModel.Dependency(
            dataManager: dependencies.dataManager,
            parentObject: inventory
        ))
        let viewModel = viewController.attach(wrapper: avm)
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewModel.showLocation
            .debug("itemSelection - InventoryLocationVC")
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
        let viewController = InventoryLocCatViewController()
        let viewModel = InventoryLocCatViewModel(dependency: dependencies, bindings: viewController.bindings,
                                                 parent: location)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewModel.modelSelected
            .debug("itemSelection - InventoryLocCatVC")
            .drive(onNext: { [weak self] selection in
                self?.showLocationItemList(with: .category(selection))
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showLocationItemList(with parent: LocationItemListParent) {
        let viewController = InventoryLocItemViewController()
        viewController.viewModel = InventoryLocItemViewModel(dependency: dependencies, parent: parent)
        navigationController.pushViewController(viewController, animated: true)
        /*
        // Selection
        viewController.tableView.rx
            .itemSelected
            .debug("itemSelection - InventoryLocItemVC")
            .subscribe(onNext: { [weak self] indexPath in
                self?.showKeypad(for: parent, atIndex: indexPath.row)
            })
            .disposed(by: disposeBag)
        */
        // Selection
        viewController.tableView.rx
            .itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showModalKeypad(for: parent, atIndex: indexPath.row)
            }
            .do(onNext: { [tableView = viewController.tableView] _ in
                // Deselect
                if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })
            .debug("itemSelection - InventoryLocItemVC")
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

// MARK: - NEW -
/*
extension InventoryCoordinator {

    fileprivate func showReviewList2(with inventory: Inventory) -> Observable<Void> {
        let viewController = InventoryReviewViewController()
        let viewModel = InventoryReviewViewModel(
            dependency: InventoryReviewViewModel.Dependency(dataManager: dependencies.dataManager, parent: inventory),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection?

        return viewController.wasPopped
            .take(1)
    }

    fileprivate func showLocationList2(with inventory: Inventory) -> Observable<Void> {
        let viewController = InventoryLocationViewController()
        let avm: Attachable<InventoryLocationViewModel> = .detached(InventoryLocationViewModel.Dependency(
            dataManager: dependencies.dataManager,
            parentObject: inventory
        ))
        let viewModel = viewController.attach(wrapper: avm)
//        let viewModel = InventoryLocationViewModel(
//            dependency: InventoryLocationViewModel.Dependency(
//                dataManager: dependencies.dataManager, parentObject: inventory),
//            bindings: viewController.bindings)
//        viewController.viewModel = viewModel

        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewModel.showLocation
            .flatMap { [weak self] selection -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                switch selection {
                case .category(let location):
                    return strongSelf.showCategoryList2(with: location)
                case .item(let location):
                    return strongSelf.showLocationItemList2(with: .location(location))
                }
            }
            .debug("itemSelection - InventoryLocationVC")
            .subscribe()
            .disposed(by: disposeBag)

        // Dismiss
        return viewController.dismissView
            .take(1)
            .do(onNext: { [weak self] _ in
                self?.navigationController.popViewController(animated: true)
            })
    }

    fileprivate func showCategoryList2(with location: InventoryLocation) -> Observable<Void> {
        let viewController = InventoryLocCatViewController()
        let viewModel = InventoryLocCatViewModel(dependency: dependencies, bindings: viewController.bindings,
                                                 parent: location)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Selection
        viewModel.modelSelected
            .asObservable()
            .flatMap { [weak self] selection -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showLocationItemList2(with: .category(selection))
            }
            .debug("itemSelection - InventoryLocCatVC")
            .subscribe()
            .disposed(by: disposeBag)

        // Dismissal
        return viewController.wasPopped
            .take(1)
    }

    fileprivate func showLocationItemList2(with parent: LocationItemListParent) -> Observable<Void> {
        let viewController = InventoryLocItemViewController()
        viewController.viewModel = InventoryLocItemViewModel(dependency: dependencies, parent: parent)
        navigationController.pushViewController(viewController, animated: true)
        /*
        // Selection
        viewController.tableView.rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.showKeypad(for: parent, atIndex: indexPath.row)
            })
            .disposed(by: disposeBag)
         */
        // Selection
        viewController.tableView.rx
            .itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showModalKeypad(for: parent, atIndex: indexPath.row)
            }
            .do(onNext: { [tableView = viewController.tableView] _ in
                // Deselect
                if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })
            .debug("itemSelection - InventoryLocItemVC")
            .subscribe()
            .disposed(by: viewController.disposeBag)

        // Dismiss
        return viewController.wasPopped
            .take(1)
    }

}
*/
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
        let viewController = InventoryLocationViewController()
        let avm: Attachable<InventoryLocationViewModel> = .detached(InventoryLocationViewModel.Dependency(
            dataManager: dependencies.dataManager,
            parentObject: inventory
        ))
        let viewModel = viewController.attach(wrapper: avm)

        navigationController.viewControllers = [viewController]
        rootViewController.present(navigationController, animated: true)

        // Selection
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
