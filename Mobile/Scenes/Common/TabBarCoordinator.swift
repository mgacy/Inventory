//
//  TabBarCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxSwift

class TabBarCoordinator: BaseCoordinator<Void>, UISplitViewControllerDelegate, UITabBarControllerDelegate {

    private let window: UIWindow
    private let dataManager: DataManager

    private let splitViewController: UISplitViewController
    private let tabBarController: TabBarController
    private let detailNavigationController: UINavigationController

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

        self.splitViewController = UISplitViewController()
        self.tabBarController = TabBarController()
        self.detailNavigationController = UINavigationController()
    }

    override func start() -> Observable<Void> {

        // Master
        let tabs: [SectionTab] = [.home, .inventory, .order, .invoice, .item]
        let coordinationResults = Observable.from(configure(tabBarController: tabBarController, withTabs: tabs)).merge()

        // Detail
        let emptyDetailViewController = EmptyDetailViewController()
        emptyDetailViewController.navigationItem.leftItemsSupplementBackButton = true
        emptyDetailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        detailNavigationController.viewControllers = [emptyDetailViewController]
        detailNavigationController.navigationBar.isTranslucent = false
        detailNavigationController.navigationBar.barTintColor = ColorPalette.hintOfRed

        // Split
        splitViewController.delegate = self
        splitViewController.viewControllers = [tabBarController, detailNavigationController]
        splitViewController.preferredDisplayMode = .allVisible

        window.rootViewController = splitViewController
        window.makeKeyAndVisible()

        return coordinationResults
    }

    private func configure(tabBarController: UITabBarController, withTabs tabs: [SectionTab]) -> [Observable<Void>] {
        tabBarController.delegate = self
        let navControllers = tabs
            .map { tab -> UINavigationController in
                let navController = NavigationController()
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

    // MARK: - UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Prevent selection of the same tab twice (which would reset the sections navigation controller)
        if tabBarController.selectedViewController === viewController {
            return false
        } else {
            return true
        }
    }

    // This is available through RxCocoa
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        //log.debug("\(#function) : didSelect: \(viewController)")

        // If svc is collapsed, detail will be on section nav controller if it is visible
        if splitViewController.isCollapsed { return }

        // Otherwise, we want to change the secondary view controller to this tab's detail view
        guard
            let navigationController = viewController as? NavigationController,
            let rootVC = navigationController.viewControllers.first else {
                fatalError("\(#function) FAILED : wrong view controller type")
        }

        switch navigationController.detailView {
        case .visible(let detailViewController):
            //log.debug("Detail View VISIBLE")
            detailViewController.navigationItem.leftItemsSupplementBackButton = true
            detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailNavigationController.viewControllers = [detailViewController]; return
        case .empty:
            //log.debug("Detail View HIDDEN")
            // We can use rootVC if we want tab-specific empty detail view controllers
            switch rootVC {
            case is HomeViewController:
                log.debug("Selected HOME Tab")
            case is InventoryDateViewController:
                log.debug("Selected INVENTORY Tab")
            case is OrderDateViewController:
                log.debug("Selected ORDER Tab")
            case is InvoiceDateViewController:
                log.debug("Selected INVOICE Tab")
            case is ItemViewController:
                log.debug("Selected ITEM Tab")
            default:
                fatalError("\(#function) FAILED : wrong view controller type")
            }
            let emptyDetailViewController = EmptyDetailViewController()
            emptyDetailViewController.navigationItem.leftItemsSupplementBackButton = true
            emptyDetailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailNavigationController.viewControllers = [emptyDetailViewController]
        }
    }

    // MARK: - UISplitViewControllerDelegate

    // MARK: Responding to Display Mode Changes

    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        //log.debug("\(#function): \(displayMode)")
        log.debug("splitViewController willChangeTo: \(displayMode.self)")
    }

    // MARK: Overriding the Interface Orientations

    // MARK: Collapsing the Interface

    // This method is called when a split view controller is collapsing its children for a transition to a compact-width
    // size class. Override this method to perform custom adjustments to the view controller hierarchy of the target
    // controller. When you return from this method, you're expected to have modified the `primaryViewController` so as
    // to be suitable for display in a compact-width split view controller, potentially using `secondaryViewController`
    // to do so. Return YES to prevent UIKit from applying its default behavior; return NO to request that UIKit
    // perform its default collapsing behavior.
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        //log.debug("\(#function)")
        return false
        /*
        guard
            let tabBarController = splitViewController.viewControllers.first as? TabBarController,
            let navigationController = tabBarController.selectedViewController as? NavigationController else {
                fatalError("\(#function) FAILED : unable to get selectedViewController")
        }
        tabBarController.collapseTabs()
        return true
        /*
        switch navigationController.detailView {
        case .empty:
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            log.debug("detailViewController is EMPTY")
            return true
        case .visible(let detailViewController):
            log.debug("detailViewController is VISIBLE")
            return true
        }
        */
        */
    }

    // MARK: Expanding the Interface

    // This method is called when a split view controller is separating its child into two children for a transition
    // from a compact-width size class to a regular-width size class. Override this method to perform custom separation
    // behavior. The controller returned from this method will be set as the secondary view controller of the split
    // view controller. When you return from this method, `primaryViewController` should have been configured for
    // display in a regular-width split view controller. If you return `nil`, then `UISplitViewController` will perform
    // its default behavior.
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        //log.debug("\(#function)")
        guard
            let tabBarController = primaryViewController as? TabBarController,
            let navigationController = tabBarController.selectedViewController as? NavigationController else {
                fatalError("\(#function) FAILED : unable to get selectedViewController")
        }
        log.debug("\(#function) : separating: \(String(describing: navigationController.topViewController.self))")

        tabBarController.separateTabs()

        switch navigationController.detailView {
        case .empty:
            //log.debug("Providing empty detail view controller")
            let emptyDetailViewController = EmptyDetailViewController()
            emptyDetailViewController.navigationItem.leftItemsSupplementBackButton = true
            emptyDetailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailNavigationController.viewControllers = [emptyDetailViewController]
            return detailNavigationController
        case .visible(let detailViewController):
            detailViewController.navigationItem.leftItemsSupplementBackButton = true
            detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailNavigationController.viewControllers = [detailViewController]
            return detailNavigationController
        }
    }

    // MARK: Overriding the Presentation Behavior

    // Customize the behavior of `showDetailViewController:` on a split view controller. Return YES to indicate that
    // you've handled the action yourself; return NO to cause the default behavior to be executed.
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        //log.debug("\(#function) - controllers: \(splitViewController.viewControllers)")
        guard
            let tabBarController = splitViewController.viewControllers.first as? UITabBarController,
            let navigationController = tabBarController.selectedViewController as? NavigationController else {
                fatalError("\(#function) FAILED : unable to get section navigation controller")
        }
        navigationController.detailView = .visible(vc)

        if splitViewController.isCollapsed {
            navigationController.pushViewController(vc, animated: true)
        } else {
            vc.navigationItem.leftItemsSupplementBackButton = true
            vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            detailNavigationController.setViewControllers([vc], animated: true)
        }
        return true
    }

}
