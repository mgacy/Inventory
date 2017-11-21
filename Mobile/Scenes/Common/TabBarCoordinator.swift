//
//  TabBarCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

enum SectionTab {
    case home
    case inventory
    case order
    case invoice
    case item

    var title: String {
        switch self {
        case .home: return "Home"
        case .inventory: return "Inventory"
        case .order: return "Order"
        case .invoice: return "Invoice"
        case .item: return "Item"
        }
    }

    var image: UIImage {
        switch self {
        case .home: return #imageLiteral(resourceName: "homeTab")
        case .inventory: return #imageLiteral(resourceName: "inventoryTab")
        case .order: return #imageLiteral(resourceName: "orderTab")
        case .invoice: return #imageLiteral(resourceName: "invoiceTab")
        case .item: return #imageLiteral(resourceName: "itemTab")
        }
    }

    var tag: Int {
        switch self {
        case .home: return 0
        case .inventory: return 1
        case .order: return 2
        case .invoice: return 3
        case .item: return 4
        }
    }
}

class TabBarCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow
    private let dataManager: DataManager
    //private let splitViewController: UISplitViewController

    init(window: UIWindow, dataManager: DataManager) {
        self.window = window
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        log.debug("\(#function)")

        let tabBarController = UITabBarController()
        let tabs: [SectionTab] = [.home, .inventory, .order, .invoice, .item]
        let coordinationResults = Observable.from(configure(tabBarController: tabBarController, withTabs: tabs)).merge()

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        //return Observable.never()
        return coordinationResults
    }

    private func configure(tabBarController: UITabBarController, withTabs tabs: [SectionTab]) -> [Observable<Void>] {
        let navControllers = tabs
            .map { tab -> UINavigationController in
                let navController = UINavigationController()
                navController.tabBarItem = UITabBarItem(title: tab.title, image: tab.image, tag: tab.tag)
                if #available(iOS 11.0, *) {
                    navController.navigationBar.prefersLargeTitles = true
                }
                return navController
            }

        tabBarController.viewControllers = navControllers
        tabBarController.view.backgroundColor = UIColor.white  // Fix dark shadow in nav bar on segue
        //window.rootViewController = tabBarController

        return zip(tabs, navControllers)
            .map { (tab, nc) in
                switch tab {
                case .home:
                    let coordinator = HomeCoordinator(navigationController: nc, dataManager: dataManager)
                    return coordinate(to: coordinator)
                    //return Observable.just(())
                case .inventory:
                    let coordinator = InventoryCoordinator(navigationController: nc, dataManager: self.dataManager)
                    return coordinate(to: coordinator)
                case .order:
                    let coordinator = OrderCoordinator(navigationController: nc, dataManager: dataManager)
                    return coordinate(to: coordinator)
                case .invoice:
                    let coordinator = InvoiceCoordinator(navigationController: nc, dataManager: dataManager)
                    return coordinate(to: coordinator)
                    //return Observable.just(())
                case .item:
                    let coordinator = ItemCoordinator(navigationController: nc, dataManager: dataManager)
                    return coordinate(to: coordinator)
                    //return Observable.just(())
                }
            }
    }

    private func prepareTabBarController(dataManager: DataManager) -> UITabBarController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateViewController(
            withIdentifier: "TabBarViewController") as? UITabBarController else {
                fatalError("Unable to instantiate tab bar controller")
        }

        // Fix dark shadow in nav bar on segue
        tabBarController.view.backgroundColor = UIColor.white

        for child in tabBarController.viewControllers ?? [] {
            guard
                let navController = child as? UINavigationController,
                let topVC = navController.topViewController else {
                    fatalError("wrong view controller type")
            }

            switch topVC {
            case is HomeViewController:
                guard let vc = topVC as? HomeViewController else { fatalError("wrong view controller type") }
                vc.viewModel = HomeViewModel(dataManager: dataManager)
            case is InventoryDateViewController:
                let inventoryCoordinator = InventoryCoordinator(navigationController: navController,
                                                                dataManager: dataManager)
                _ = coordinate(to: inventoryCoordinator)
                //guard let vc = topVC as? InventoryDateViewController else { fatalError("wrong view controller type") }
                //vc.viewModel = InventoryDateViewModel(dataManager: dataManager,
                //                                      rowTaps: vc.selectedObjects.asObservable())
            case is OrderDateViewController:
                guard let vc = topVC as? OrderDateViewController else { fatalError("wrong view controller type") }
                vc.viewModel = OrderDateViewModel(dataManager: dataManager, rowTaps: vc.selectedObjects.asObservable())
            case is InvoiceDateViewController:
                guard let vc = topVC as? InvoiceDateViewController else { fatalError("wrong view controller type") }
                vc.viewModel = InvoiceDateViewModel(dataManager: dataManager,
                                                    rowTaps: vc.selectedObjects.asObservable())
            case is InitialLoginViewController:
                guard let vc = topVC as? InitialLoginViewController else { fatalError("wrong view controller type") }
                vc.viewModel = InitialLoginViewModel(dataManager: dataManager)
            case is ItemViewController:
                guard let vc = topVC as? ItemViewController else { fatalError("wrong view controller type") }
                vc.viewModel = ItemViewModel(dataManager: dataManager, rowTaps: vc.rowTaps.asObservable())
            default:
                fatalError("wrong view controller type")
            }
        }
        return tabBarController
    }

}
