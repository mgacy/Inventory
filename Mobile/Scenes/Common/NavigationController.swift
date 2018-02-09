//
//  NavigationController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    var detailView: DetailView<UIViewController> = .empty

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = ColorPalette.hintOfRed
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        //log.debug("\(#function) : \(String(describing: topViewController.self))")
        if case .visible(let detailViewController) = detailView {
            if topViewController === detailViewController {
                //log.debug("\(#function) : POPPED DETAIL")
                detailView = .empty
            } else {
                // Set detail view controller to empty to prevent confusion
                // FIXME: it's really ugly that we are reaching up into splitViewController to get its detail nav controller
                if
                    let splitViewController = splitViewController,
                    splitViewController.viewControllers.count > 1,
                    let detailNavigationController = splitViewController.viewControllers.last as? UINavigationController
                {
                    detailNavigationController.setViewControllers([makeEmptyViewController()], animated: true)
                    detailView = .empty
                }
            }
        }
        return super.popViewController(animated: animated)
    }

}

// MARK: - PrimaryContainerType

extension NavigationController: PrimaryContainerType {

    /// Add detail view controller to `viewControllers` if it is visible.
    func collapseDetail() {
        switch detailView {
        case .visible(let detailViewController):
            viewControllers += [detailViewController]
        case .empty:
            return
        }
    }

    /// Remove detail view controller from `viewControllers` if it is visible.
    func separateDetail() {
        switch detailView {
        case .visible:
            viewControllers.removeLast()
        case .empty:
            return
        }
    }

    func makeEmptyViewController() -> UIViewController {
        return EmptyDetailViewController()
    }

}

}
