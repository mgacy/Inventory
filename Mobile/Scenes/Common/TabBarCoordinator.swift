//
//  TabBarCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class TabBarCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow
    private let dataManager: DataManager
    //private let splitViewController: UISplitViewController

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

    // MARK: - Lifecycle

    init(window: UIWindow, dataManager: DataManager) {
        self.window = window
        self.dataManager = dataManager
    }

    override func start() -> Observable<Void> {
        let tabBarController = UITabBarController()
        let tabs: [SectionTab] = [.home, .inventory, .order, .invoice, .item]
        let coordinationResults = Observable.from(configure(tabBarController: tabBarController, withTabs: tabs)).merge()

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

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

        return zip(tabs, navControllers)
            .map { (tab, navCtrl) in
                switch tab {
                case .home:
                    let coordinator = HomeCoordinator(navigationController: navCtrl, dataManager: dataManager)
                    return coordinate(to: coordinator)
                case .inventory:
                    let coordinator = InventoryCoordinator(navigationController: navCtrl, dataManager: self.dataManager)
                    return coordinate(to: coordinator)
                case .order:
                    let coordinator = OrderCoordinator(navigationController: navCtrl, dataManager: dataManager)
                    return coordinate(to: coordinator)
                case .invoice:
                    let coordinator = InvoiceCoordinator(navigationController: navCtrl, dataManager: dataManager)
                    return coordinate(to: coordinator)
                case .item:
                    let coordinator = ItemCoordinator(navigationController: navCtrl, dataManager: dataManager)
                    return coordinate(to: coordinator)
                }
            }
    }

}
