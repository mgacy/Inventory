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

// MARK: - Delegate Object

final class SplitViewDelegate: NSObject {

    let detailNavigationController: UINavigationController

    init(detailNavigationController: UINavigationController) {
        self.detailNavigationController = detailNavigationController
        super.init()
    }

    func updateSecondaryWithDetail(from primaryContainer: PrimaryContainerType, animated: Bool = false) {
        switch primaryContainer.detailView {
        case .collapsed(let detailViewController):
            detailNavigationController.setViewControllers([detailViewController], animated: animated)
        case .separated(let detailViewController):
            detailNavigationController.setViewControllers([detailViewController], animated: animated)
        case .placeholder:
            detailNavigationController.setViewControllers([primaryContainer.makePlaceholderViewController()],
                                                          animated: animated)
        }
    }

    func replaceDetail(withEmpty viewController: UIViewController & PlaceholderViewControllerType) {
        detailNavigationController.setViewControllers([viewController], animated: true)
    }

}

// MARK: - UITabBarControllerDelegate
extension SplitViewDelegate: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Prevent selection of the same tab twice (which would reset its navigation controller)
        return tabBarController.selectedViewController === viewController ? false : true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard
            let splitViewController = tabBarController.splitViewController,
            let selectedNavController = viewController as? PrimaryContainerType else {
                fatalError("\(#function) FAILED : wrong view controller type")
        }
        // If split view controller is collapsed, detail view will already be on `selectedNavController.viewControllers`;
        // otherwise, we need to change the secondary view controller to the selected tab's detail view.
        if !splitViewController.isCollapsed {
            updateSecondaryWithDetail(from: selectedNavController)
        }
    }

}

// MARK: - UISplitViewControllerDelegate
extension SplitViewDelegate: UISplitViewControllerDelegate {

    // MARK: Collapsing the Interface

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard
            let tabBarController = splitViewController.viewControllers.first as? UITabBarController,
            let navigationControllers = tabBarController.viewControllers as? [PrimaryContainerType] else {
                fatalError("\(#function) FAILED : wrong view controller type")
        }

        navigationControllers.forEach { $0.collapseDetail() }
        return true // Prevent UIKit from performing default collapse behavior
    }

    // MARK: Expanding the Interface

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard
            let tabBarController = primaryViewController as? UITabBarController,
            let navigationControllers = tabBarController.viewControllers as? [PrimaryContainerType],
            let selectedNavController = tabBarController.selectedViewController as? PrimaryContainerType else {
                fatalError("\(#function) FAILED : wrong view controller type")
        }

        navigationControllers.forEach { $0.separateDetail() }

        // There is no point in hiding the primary view controller with a placeholder detail view
        if case .placeholder = selectedNavController.detailView, splitViewController.preferredDisplayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        updateSecondaryWithDetail(from: selectedNavController)
        return detailNavigationController
    }

    // MARK: Overriding the Presentation Behavior

    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        guard
            let tabBarController = splitViewController.viewControllers.first as? UITabBarController,
            let selectedNavController = tabBarController.selectedViewController as? UINavigationController
                & PrimaryContainerType else {
                    fatalError("\(#function) FAILED : wrong view controller type")
        }

        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem

        if splitViewController.isCollapsed {
            selectedNavController.pushViewController(vc, animated: true)
            selectedNavController.detailView = .collapsed(vc)
        } else {
            switch selectedNavController.detailView {
            // Animate only the initial presentation of the detail vc
            case .placeholder:
                detailNavigationController.setViewControllers([vc], animated: true)
            default:
                detailNavigationController.setViewControllers([vc], animated: false)
            }
            selectedNavController.detailView = .separated(vc)
        }
        return true // Prevent UIKit from performing default behavior
    }

}
