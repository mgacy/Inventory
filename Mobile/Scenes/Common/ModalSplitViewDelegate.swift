//
//  ModalSplitViewDelegate.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/27/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

final class ModalSplitViewDelegate: NSObject {

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

// MARK: - UISplitViewControllerDelegate
extension ModalSplitViewDelegate: UISplitViewControllerDelegate {

    // MARK: Collapsing the Interface

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard
            let navigationController = splitViewController.viewControllers.first as? PrimaryContainerType else {
                fatalError("\(#function) FAILED : wrong view controller type")
        }

        navigationController.collapseDetail()
        return true // Prevent UIKit from performing default collapse behavior
    }

    // MARK: Expanding the Interface

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let navigationController = primaryViewController as? PrimaryContainerType else {
            fatalError("\(#function) FAILED : wrong view controller type")
        }

        navigationController.separateDetail()

        // There is no point in hiding the primary view controller with a placeholder detail view
        if
            case .placeholder = navigationController.detailView,
            splitViewController.preferredDisplayMode == .primaryHidden
        {
            splitViewController.preferredDisplayMode = .allVisible
        }
        updateSecondaryWithDetail(from: navigationController)
        return detailNavigationController
    }

    // MARK: Overriding the Presentation Behavior

    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        guard
            let navigationController = splitViewController.viewControllers.first as? UINavigationController
                & PrimaryContainerType else {
                    fatalError("\(#function) FAILED : wrong view controller type")
        }

        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem

        if splitViewController.isCollapsed {
            navigationController.pushViewController(vc, animated: true)
            navigationController.detailView = .collapsed(vc)
        } else {
            switch navigationController.detailView {
            // Animate only the initial presentation of the detail vc
            case .placeholder:
                detailNavigationController.setViewControllers([vc], animated: true)
            default:
                detailNavigationController.setViewControllers([vc], animated: false)
            }
            navigationController.detailView = .separated(vc)
        }
        return true // Prevent UIKit from performing default behavior
    }

}
