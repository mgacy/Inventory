//
//  TabBarController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    // MARK: - A

    override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
        //log.debug("\(#function)")
        collapseTabs()
    }

    override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        //log.debug("separateSecondaryViewController")
        return viewControllers?
            .flatMap { vc in
                guard let navController = vc as? PrimaryContainerType else { return nil }
                navController.separateDetail()
                return vc
            }
            .filter { $0 == self.selectedViewController }
            .first
    }

    // MARK: - B

    /// Call `PrimaryContainerType.collapseDetail()` on children to add visible detail view controllers.
    func collapseTabs() {
        guard let vcs = viewControllers else { return }
        vcs.forEach { viewController in
            guard let navController = viewController as? PrimaryContainerType else {
                fatalError("\(#function) FAILED : wrong view controller type")
            }
            navController.collapseDetail()
        }
    }

    /// Call `PrimaryContainerType.separateDetail()` on children to remove visible detail view controllers.
    func separateTabs() {
        guard let vcs = viewControllers else { return }
        vcs.forEach { viewController in
            guard let navController = viewController as? PrimaryContainerType else {
                fatalError("\(#function) FAILED : wrong view controller type")
            }
            navController.separateDetail()
        }
    }

}
