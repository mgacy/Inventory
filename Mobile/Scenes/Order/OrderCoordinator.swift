//
//  OrderCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class OrderCoordinator: BaseCoordinator<Void> {

    fileprivate let navigationController: UINavigationController
    fileprivate let dataManager: DataManager

    init(navigationController: UINavigationController, dataManager: DataManager) {
        self.navigationController = navigationController
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        let viewController = OrderDateViewController.initFromStoryboard(name: "Main")
        let viewModel = OrderDateViewModel(dataManager: dataManager,
                                           rowTaps: viewController.selectedObjects.asObservable())
        viewController.viewModel = viewModel
        navigationController.viewControllers = [viewController]

        // Selection
        viewModel.showCollection
            .subscribe(onNext: { [weak self] selection in
                log.debug("\(#function) SELECTED / CREATED: \(selection)")
                switch selection.uploaded {
                case true:
                    self?.showVendorList(collection: selection)
                case false:
                    self?.showContainer(collection: selection)
                }
            })
            .disposed(by: disposeBag)

        return Observable.never()
    }

    // MARK: - Sections

    // MARK: Container

    fileprivate typealias ContainerConfigurationResult = (OrderContainerViewController, OrderLocationViewController,
                                                          OrderVendorViewModel)

    fileprivate func configureContainer(with collection: OrderCollection) -> ContainerConfigurationResult {
        // OrderVendorViewController
        let vendorsController = OrderVendorViewController.initFromStoryboard(name: "OrderVendorViewController")
        let vendorsViewModel = OrderVendorViewModel(dataManager: dataManager, parentObject: collection,
                                                    rowTaps: vendorsController.selectedObjects.asObservable(),
                                                    completeTaps: vendorsController.completeButtonItem.rx.tap
                                                        .asObservable())
        vendorsController.viewModel = vendorsViewModel

        // OrderLocationViewController
        guard let locationsController = OrderLocationViewController.instance() else {
            fatalError("\(#function) FAILED : wrong view controller")
        }
        let locationsViewModel = OrderLocationViewModel(dataManager: dataManager, collection: collection)
        locationsController.viewModel = locationsViewModel

        // OrderContainerViewController
        let containerController = OrderContainerViewController.initFromStoryboard(name: "OrderContainerViewController")
        let viewModel = OrderContainerViewModel(dataManager: dataManager, parentObject: collection,
                                                completeTaps: containerController.completeButtonItem.rx.tap
                                                    .asObservable())
        containerController.viewModel = viewModel
        containerController.configureChildControllers(vendorsController: vendorsController,
                                                      locationsController: locationsController)

        return (containerController, locationsController, vendorsViewModel)
    }

    fileprivate func showContainer(collection: OrderCollection) {
        let (containerController, locationsController, vendorsViewModel) = configureContainer(with: collection)
        let factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)
        navigationController.pushViewController(containerController, animated: true)

        // Selction - Vendor
        vendorsViewModel.showNext
            .subscribe(onNext: { [weak self] segue in
                switch segue {
                case .back:
                    self?.navigationController.popViewController(animated: true)
                case .item(let order):
                    self?.showItemList(order: order)
                }
            })
            .disposed(by: disposeBag)

        // Selection - Location
        locationsController.tableView.rx
            .modelSelected(RemoteLocation.self)
            .subscribe(onNext: { [weak self] location in
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }
                switch location.locationType {
                case .category:
                    strongSelf.showLocationCategoryList(location: location, factory: factory)
                case .item:
                    strongSelf.showLocationItemList(parent: OrderLocItemParent.location(location), factory: factory)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: Vendor

    fileprivate func showVendorList(collection: OrderCollection) {
        let viewController = OrderVendorViewController.initFromStoryboard(name: "OrderVendorViewController")
        let viewModel = OrderVendorViewModel(dataManager: dataManager, parentObject: collection,
                                             rowTaps: viewController.selectedObjects.asObservable(),
                                             completeTaps: viewController.completeButtonItem.rx.tap.asObservable())
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        viewModel.showNext
            .subscribe(onNext: { [weak self] segue in
                switch segue {
                case .back:
                    self?.navigationController.popViewController(animated: true)
                case .item(let order):
                    self?.showItemList(order: order)
                }
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showItemList(order: Order) {
        guard let viewController = OrderItemViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderViewModel(dataManager: dataManager, parentObject: order)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Pop on uploadResults?

        // Selection
        viewController.selectedIndices
            .subscribe(onNext: { [weak self] index in
                self?.showKeypad(order: order, atIndex: index.row)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showKeypad(order: Order, atIndex index: Int) {
        guard let viewController = OrderKeypadViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderKeypadViewModel(dataManager: dataManager, for: order, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: Location

    fileprivate func showLocationList(collection: OrderCollection) {
        guard let viewController = OrderLocationViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderLocationViewModel(dataManager: dataManager, collection: collection)
        viewController.viewModel = viewModel
        //navigationController.pushViewController(viewController, animated: true)

        let factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)

        // Navigation
        viewController.tableView.rx
            .modelSelected(RemoteLocation.self)
            .subscribe(onNext: { [weak self] location in
                switch location.locationType {
                case .category:
                    self?.showLocationItemList(parent: OrderLocItemParent.location(location), factory: factory)
                case .item:
                    let parent = OrderLocItemParent.location(location)
                    self?.showLocationItemList(parent: parent, factory: factory)
                }
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showLocationCategoryList(location: RemoteLocation, factory: OrderLocationFactory) {
        guard let viewController = OrderLocCatViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderLocCatViewModel(dataManager: dataManager, location: location, factory: factory)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Navigation
        viewController.tableView.rx
            .modelSelected(RemoteItemCategory.self)
            .subscribe(onNext: { [weak self] category in
                log.debug("We selected: \(category)")

                let parent = OrderLocItemParent.category(category)
                self?.showLocationItemList(parent: parent, factory: factory)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showLocationItemList(parent: OrderLocItemParent, factory: OrderLocationFactory) {
        guard let viewController = OrderLocItemViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderLocItemViewModel(dataManager: dataManager, parent: parent, factory: factory)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Navigation
        viewController.tableView.rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                log.debug("We selected: \(indexPath)")
                self?.showKeypad(orderItems: viewModel.orderItems, atIndex: indexPath.row)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showKeypad(orderItems: [OrderItem], atIndex index: Int) {
        guard let viewController = OrderKeypadViewController.instance() else {
            fatalError("Wrong view controller")
        }
        let viewModel = OrderKeypadViewModel(dataManager: dataManager, with: orderItems, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

}

// MARK: - Modal Display from Home

class ModalOrderCoordinator: OrderCoordinator {

    private let rootViewController: UIViewController
    private let collection: OrderCollection

    init(rootViewController: UIViewController, dataManager: DataManager, collection: OrderCollection) {
        self.rootViewController = rootViewController
        self.collection = collection
        super.init(navigationController: UINavigationController(), dataManager: dataManager)
    }

    override func start() -> Observable<Void> {
        let (containerController, locationsController, vendorsViewModel) = configureContainer(with: collection)
        let factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)

        navigationController.viewControllers = [containerController]
        rootViewController.present(navigationController, animated: true)

        // Selction - Vendor
        vendorsViewModel.showNext
            .subscribe(onNext: { [weak self] segue in
                switch segue {
                case .back:
                    self?.navigationController.popViewController(animated: true)
                case .item(let order):
                    self?.showItemList(order: order)
                }
            })
            .disposed(by: disposeBag)

        // Selection - Location
        locationsController.tableView.rx
            .modelSelected(RemoteLocation.self)
            .subscribe(onNext: { [weak self] location in
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }
                switch location.locationType {
                case .category:
                    strongSelf.showLocationCategoryList(location: location, factory: factory)
                case .item:
                    strongSelf.showLocationItemList(parent: OrderLocItemParent.location(location), factory: factory)
                }
            })
            .disposed(by: disposeBag)

        // Cancel
        return containerController.cancelButtonItem.rx.tap
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
