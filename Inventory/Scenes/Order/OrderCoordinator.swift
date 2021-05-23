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
        let viewModel = OrderDateViewModel(dependency: dependencies, bindings: viewController.bindings)
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

    fileprivate typealias ContainerConfigurationResult = (OrderContainerViewController, OrderLocationViewModel,
        OrderVendorViewModel)

    fileprivate func configureContainer(with collection: OrderCollection) -> ContainerConfigurationResult {
        // OrderVendorViewController
        let vendorsController = OrderVendorViewController.instance()
        let vendorsViewModel = OrderVendorViewModel(dataManager: dependencies.dataManager, parentObject: collection,
                                                    rowTaps: vendorsController.selectedObjects.asObservable(),
                                                    completeTaps: vendorsController.completeButtonItem.rx.tap
                                                        .asObservable())
        vendorsController.viewModel = vendorsViewModel

        // OrderLocationViewController
        let locationsController = OrderLocationViewController()
        let locationsViewModel = OrderLocationViewModel(
            dependency: OrderLocationViewModel.Dependency(dataManager: dependencies.dataManager,
                                                          collection: collection),
            bindings: locationsController.bindings
        )
        locationsController.viewModel = locationsViewModel

        // OrderContainerViewController
        let containerController = OrderContainerViewController()
        let viewModel = OrderContainerViewModel(dataManager: dependencies.dataManager, parentObject: collection,
                                                completeTaps: containerController.completeButtonItem.rx.tap
                                                    .asObservable())
        containerController.viewModel = viewModel
        containerController.configureChildControllers(vendorsController: vendorsController,
                                                      locationsController: locationsController)

        return (containerController, locationsViewModel, vendorsViewModel)
    }

    fileprivate func showContainer(collection: OrderCollection) {
        let (containerController, locationsViewModel, vendorsViewModel) = configureContainer(with: collection)
        navigationController.pushViewController(containerController, animated: true)

        // TODO: replace `.subscribe(onNext: { ... }) in the following with:
        /// .subscribe()
        /// .do(onNext: { ... })

        // Selection - Vendor
        vendorsViewModel.showNext
            .debug("vendorSelection - OrderContainerVC")
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
        locationsViewModel.selectedLocation
            .debug("locationSelection - OrderContainerVC")
            .subscribe(onNext: { [weak self] location in
                guard let strongSelf = self, let locationType = LocationType(rawValue: location.locationType) else {
                    return
                }
                switch locationType {
                case .category:
                    strongSelf.showLocationCategoryList(location: location)
                case .item:
                    strongSelf.showLocationItemList(parent: .location(location))
                }
            })
            .disposed(by: disposeBag)

        /*
        // Selection - Location
        locationsController.tableView.rx
            .modelSelected(RemoteLocation.self)
            //.debug("Selection")
            .map { [weak self] location in
                guard let strongSelf = self else { return }
                switch location.locationType {
                case .category:
                    strongSelf.showLocationCategoryList(location: location)
                case .item:
                    strongSelf.showLocationItemList(parent: OrderLocItemParent.location(location))
                }
            }
            .do(onNext: { [tableView = locationsController.tableView] _ in
                // Deselect
                if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
            })
            .debug("locationSelection - \(locationsController)")
            .subscribe()
            .disposed(by: disposeBag)
        */
        // Completion
        containerController.viewModel.popView
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { fatalError("\(#function) FAILED : unable to get self") }
                strongSelf.navigationController.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: Vendor

    /// Used when showing uploaded OrderCollections
    fileprivate func showVendorList(collection: OrderCollection) {
        let viewController = OrderVendorViewController.instance()
        let viewModel = OrderVendorViewModel(dataManager: dependencies.dataManager, parentObject: collection,
                                             rowTaps: viewController.selectedObjects.asObservable(),
                                             completeTaps: viewController.completeButtonItem.rx.tap.asObservable())
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        viewModel.showNext
            .debug("itemSelection - OrderVendorVC")
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
        let viewController = OrderItemViewController()
        let viewModel = OrderViewModel(
            dependency: OrderViewModel.Dependency(dataManager: dependencies.dataManager, parentObject: order),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)

        // Pop on uploadResults?

        // Navigation
        viewController.tableView.rx
            .itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { fatalError("Unable to get self") }
                return strongSelf.showKeypad(order: order, atIndex: indexPath.row)
            }
            .do(onNext: { [tableView = viewController.tableView] _ in
                // Deselect
                if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }
                // Update
                viewModel.updateOrderStatus()
                viewController.headerView.messageButton.isEnabled = viewModel.canMessageOrder
            })
            .debug("itemSelection - OrderItemVC")
            .subscribe()
            //.disposed(by: disposeBag)
            .disposed(by: viewController.disposeBag)
    }

    func showKeypad(order: Order, atIndex index: Int) -> Observable<Void> {
        let keypadDependencies = OrderKeypadViewModel.Dependency(dataManager: dependencies.dataManager,
                                                                 displayType: .vendor(order), index: index)
        let keypadCoordinator = OrderKeypadCoordinator(rootViewController: navigationController,
                                                       dependencies: keypadDependencies)
        return coordinate(to: keypadCoordinator)
    }

    // MARK: Location
    /*
    fileprivate func showLocationList(collection: OrderCollection) {
        let viewController = OrderLocationViewController()
        let viewModel = OrderLocationViewModel(
            dependency: OrderLocationViewModel.Dependency(dataManager: dependencies.dataManager,
                                                           collection: collection),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        //navigationController.pushViewController(viewController, animated: true)

        // Navigation
        viewModel.selectedLocation
            .debug("itemSelection - OrderLocationVC")
            .subscribe(onNext: { [weak self] location in
                guard let strongSelf = self, let locationType = LocationType(rawValue: location.locationType) else {
                    return
                }
                switch locationType {
                case .category:
                    strongSelf.showLocationItemList(parent: .location(location))
                case .item:
                    strongSelf.showLocationItemList(parent: .location(location))
                }
            })
            .disposed(by: disposeBag)
    }
    */
    fileprivate func showLocationCategoryList(location: OrderLocation) {
        let viewController = OrderLocCatViewController()
        let viewModel = OrderLocCatViewModel(
            dependency: OrderLocCatViewModel.Dependency(dataManager: dependencies.dataManager, location: location),
            bindings: viewController.bindings)
        viewController.viewModel = viewModel
        navigationController.pushViewController(viewController, animated: true)

        // Navigation
        viewModel.selectedCategory
            .debug("itemSelection - OrderLocCatVC")
            .subscribe(onNext: { [weak self] category in
                self?.showLocationItemList(parent: .category(category))
            })
            .disposed(by: disposeBag)
    }

    fileprivate func showLocationItemList(parent: OrderLocItemParent) {
        var viewController: MGTableViewController & OrderLocItemViewControllerType
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            viewController = OrderLocItemViewController()
        case .pad:
            viewController = OrderLocItemPadViewController()
        default:
            fatalError("Unable to setup bindings for unrecognized device: \(UIDevice.current.userInterfaceIdiom)")
        }
        let viewModel = OrderLocItemViewModel(
            dependency: OrderLocItemViewModel.Dependency(dataManager: dependencies.dataManager, parent: parent),
            bindings: viewController.bindings)

        viewController.viewModel = viewModel
        navigationController.showDetailViewController(viewController, sender: nil)

        // Navigation
        let tablewViewController = viewController as MGTableViewController
        tablewViewController.tableView.rx
            .itemSelected
            .flatMap { [weak self] indexPath -> Observable<Void> in
                guard let strongSelf = self else { return .empty() }
                return strongSelf.showKeypad(parent: parent, atIndex: indexPath.row)
            }
            .do(onNext: { [tableView = tablewViewController.tableView] _ in
                tableView.reloadData()
            })
            .debug("itemSelection - OrderLocItemVC")
            .subscribe()
            .disposed(by: tablewViewController.disposeBag)
    }

    func showKeypad(parent: OrderLocItemParent, atIndex index: Int) -> Observable<Void> {
        let keypadDependencies = OrderKeypadViewModel.Dependency(dataManager: dependencies.dataManager,
                                                                 displayType: .location(parent), index: index)
        let keypadCoordinator = OrderKeypadCoordinator(rootViewController: navigationController,
                                                       dependencies: keypadDependencies)
        return coordinate(to: keypadCoordinator)
    }

}

// MARK: - Modal Display from Home

class ModalOrderCoordinator: OrderCoordinator {

    private let rootViewController: UIViewController
    private let collection: OrderCollection
    // swiftlint:disable:next weak_delegate
    private var viewDelegate: ModalSplitViewDelegate

    init(rootViewController: UIViewController, dependencies: Dependencies, collection: OrderCollection) {
        self.rootViewController = rootViewController
        self.collection = collection

        self.viewDelegate = ModalSplitViewDelegate(detailNavigationController: DetailNavigationController())
        // swiftlint:disable:next inclusive_language
        let masterNavigationController = NavigationController(withPopDetailCompletion: viewDelegate.replaceDetail)
        viewDelegate.updateSecondaryWithDetail(from: masterNavigationController)

        super.init(navigationController: masterNavigationController, dependencies: dependencies)
    }

    override func start() -> Observable<Void> {
        let (containerController, locationsViewModel, vendorsViewModel) = configureContainer(with: collection)
        navigationController.viewControllers = [containerController]

        let splitViewController = UISplitViewController()
        splitViewController.delegate = viewDelegate
        splitViewController.viewControllers = [navigationController, viewDelegate.detailNavigationController]
        splitViewController.preferredDisplayMode = .allVisible

        // Configure cancel button and present
        containerController.navigationItem.leftBarButtonItem = containerController.cancelButtonItem
        rootViewController.present(splitViewController, animated: true)

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
        locationsViewModel.selectedLocation
            .debug("locationSelection - OrderContainerVC")
            .subscribe(onNext: { [weak self] location in
                log.debug("Selected: \(location)")
                guard let strongSelf = self, let locationType = LocationType(rawValue: location.locationType) else {
                    return
                }
                switch locationType {
                case .category:
                    strongSelf.showLocationCategoryList(location: location)
                case .item:
                    strongSelf.showLocationItemList(parent: .location(location))
                }
            })
            .disposed(by: disposeBag)

        // Cancel / Completion
        let cancelTaps = containerController.cancelButtonItem.rx.tap.asObservable()
        return Observable.merge(cancelTaps, containerController.viewModel.popView)
            .take(1)
            .do(onNext: { [weak self] _ in self?.rootViewController.dismiss(animated: true) })
    }

}
