//
//  OrderCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class OrderCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasDataManager

    fileprivate let navigationController: UINavigationController
    fileprivate let dependencies: Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    override func start() -> Observable<Void> {
        let viewController = OrderDateViewController.instance()
        let viewModel = OrderDateViewModel(dataManager: dependencies.dataManager,
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
        let vendorsViewModel = OrderVendorViewModel(dataManager: dependencies.dataManager, parentObject: collection,
                                                    rowTaps: vendorsController.selectedObjects.asObservable(),
                                                    completeTaps: vendorsController.completeButtonItem.rx.tap
                                                        .asObservable())
        vendorsController.viewModel = vendorsViewModel

        // OrderLocationViewController
        let locationsController = OrderLocationViewController.instance()
        let locationsViewModel = OrderLocationViewModel(dataManager: dependencies.dataManager, collection: collection)
        locationsController.viewModel = locationsViewModel

        // OrderContainerViewController
        let containerController = OrderContainerViewController.initFromStoryboard(name: "OrderContainerViewController")
        let viewModel = OrderContainerViewModel(dataManager: dependencies.dataManager, parentObject: collection,
                                                completeTaps: containerController.completeButtonItem.rx.tap
                                                    .asObservable())
        containerController.viewModel = viewModel
        containerController.configureChildControllers(vendorsController: vendorsController,
                                                      locationsController: locationsController)

        return (containerController, locationsController, vendorsViewModel)
    }

    fileprivate func showContainer(collection: OrderCollection) {
        let (containerController, locationsController, vendorsViewModel) = configureContainer(with: collection)
        let factory = OrderLocationFactory(collection: collection, in: dependencies.dataManager.managedObjectContext)
        navigationController.pushViewController(containerController, animated: true)

        /// TODO: replace `.subscribe(onNext: { ... }) in the following with:
        /// .subscribe()
        /// .do(onNext: { ... })

        // Selection - Vendor
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

        // Completion
        containerController.viewModel.popView
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }
                strongSelf.navigationController.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: Vendor

    fileprivate func showVendorList(collection: OrderCollection) {
        let viewController = OrderVendorViewController.initFromStoryboard(name: "OrderVendorViewController")
        let viewModel = OrderVendorViewModel(dataManager: dependencies.dataManager, parentObject: collection,
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
        let viewController = OrderItemViewController.instance()
        let viewModel = OrderViewModel(dataManager: dependencies.dataManager, parentObject: order)
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

    func showKeypad(order: Order, atIndex index: Int) {
        let viewController = OrderKeypadViewController.instance()
        let viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, for: order, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)
    }

    // MARK: Location

    fileprivate func showLocationList(collection: OrderCollection) {
        let viewController = OrderLocationViewController.instance()
        let viewModel = OrderLocationViewModel(dataManager: dependencies.dataManager, collection: collection)
        viewController.viewModel = viewModel
        //navigationController.pushViewController(viewController, animated: true)

        let factory = OrderLocationFactory(collection: collection, in: dependencies.dataManager.managedObjectContext)

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
        let viewController = OrderLocCatViewController.instance()
        let viewModel = OrderLocCatViewModel(dataManager: dependencies.dataManager,
                                             location: location, factory: factory)
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
        let viewController = OrderLocItemViewController.instance()
        let viewModel = OrderLocItemViewModel(dataManager: dependencies.dataManager, parent: parent, factory: factory)
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

    func showKeypad(orderItems: [OrderItem], atIndex index: Int) {
        let viewController = OrderKeypadViewController.instance()
        let viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, with: orderItems, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)
    }

}

// MARK: - Modal Display from Home

class ModalOrderCoordinator: OrderCoordinator {

    private let rootViewController: UIViewController
    private let collection: OrderCollection

    init(rootViewController: UIViewController, dependencies: Dependencies, collection: OrderCollection) {
        self.rootViewController = rootViewController
        self.collection = collection
        super.init(navigationController: UINavigationController(), dependencies: dependencies)
    }

    override func start() -> Observable<Void> {
        let (containerController, locationsController, vendorsViewModel) = configureContainer(with: collection)
        let factory = OrderLocationFactory(collection: collection, in: dependencies.dataManager.managedObjectContext)

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

        // Cancel / Completion
        let cancelTaps = containerController.cancelButtonItem.rx.tap.asObservable()
        return Observable.merge(cancelTaps, containerController.viewModel.popView)
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

    override func showKeypad(order: Order, atIndex index: Int) {
        let viewController = OrderKeypadViewController.instance()
        let viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, for: order, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

    override func showKeypad(orderItems: [OrderItem], atIndex index: Int) {
        let viewController = OrderKeypadViewController.instance()
        let viewModel = OrderKeypadViewModel(dataManager: dependencies.dataManager, with: orderItems, atIndex: index)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)
    }

}
