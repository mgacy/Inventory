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
                guard let navController = vc as? NavigationController else { return nil }
                navController.separate()
                return vc
            }
            .filter { $0 == self.selectedViewController }
            .first
    }

    // MARK: - B

    func collapseTabs() {
        //log.debug("\(#function)")
        guard let vcs = viewControllers else { return }
        vcs.forEach { viewController in
            guard let navController = viewController as? NavigationController else {
                fatalError("\(#function) FAILED : wrong view controller type")
            }
            navController.collapse()
        }
    }

    func separateTabs() {
        //log.debug("\(#function)")
        guard let vcs = viewControllers else { return }
        vcs.forEach { viewController in
            guard let navController = viewController as? NavigationController else {
                fatalError("\(#function) FAILED : wrong view controller type")
            }
            navController.separate()
        }
    }

}
