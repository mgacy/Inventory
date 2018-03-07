//
//  TabBarCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class TabBarCoordinator: BaseCoordinator<Void> {
    typealias Dependencies = HasUserManager & HasDataManager

    private let window: UIWindow
    private let dependencies: Dependencies

    // swiftlint:disable:next weak_delegate
    private var viewDelegate: SplitViewDelegate

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

    }

    // MARK: - Lifecycle

    init(window: UIWindow, dependencies: Dependencies) {
        self.window = window
        self.dependencies = dependencies

        let detailNavigationController = DetailNavigationController()
        self.viewDelegate = SplitViewDelegate(detailNavigationController: detailNavigationController)
    }

    override func start() -> Observable<Void> {
        let tabBarController = UITabBarController()
        let tabs: [SectionTab] = [.home, .inventory, .order, .invoice, .item]
        let coordinationResults = Observable.from(configure(tabBarController: tabBarController, withTabs: tabs)).merge()

        if let initialPrimaryView = tabBarController.selectedViewController as? PrimaryContainerType {
            viewDelegate.updateSecondaryWithDetail(from: initialPrimaryView)
        }

        let splitViewController = UISplitViewController()
        splitViewController.delegate = viewDelegate
        splitViewController.viewControllers = [tabBarController, viewDelegate.detailNavigationController]
        splitViewController.preferredDisplayMode = .allVisible

        window.rootViewController = splitViewController
        window.makeKeyAndVisible()

        return coordinationResults
    }

    private func configure(tabBarController: UITabBarController, withTabs tabs: [SectionTab]) -> [Observable<Void>] {
        let navControllers = tabs
            .map { tab -> UINavigationController in
                let navController = NavigationController(withPopDetailCompletion: viewDelegate.replaceDetail)
                navController.tabBarItem = UITabBarItem(title: tab.title, image: tab.image, selectedImage: nil)
                if #available(iOS 11.0, *) {
                    navController.navigationBar.prefersLargeTitles = true
                }
                return navController
        }

        tabBarController.viewControllers = navControllers
        tabBarController.delegate = viewDelegate
        tabBarController.view.backgroundColor = UIColor.white  // Fix dark shadow in nav bar on segue

        return zip(tabs, navControllers)
            .map { (tab, navCtrl) in
                switch tab {
                case .home:
                    let coordinator = HomeCoordinator(navigationController: navCtrl, dependencies: dependencies)
                    return coordinate(to: coordinator)
                case .inventory:
                    let coordinator = InventoryCoordinator(navigationController: navCtrl, dependencies: dependencies)
                    return coordinate(to: coordinator)
                case .order:
                    let coordinator = OrderCoordinator(navigationController: navCtrl, dependencies: dependencies)
                    return coordinate(to: coordinator)
                case .invoice:
                    let coordinator = InvoiceCoordinator(navigationController: navCtrl, dependencies: dependencies)
                    return coordinate(to: coordinator)
                case .item:
                    let coordinator = ItemCoordinator(navigationController: navCtrl, dependencies: dependencies)
                    return coordinate(to: coordinator)
                }
            }
    }

}
