//
//  NavigationController.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

// MARK: - Protocols

protocol DetailViewControllerType where Self: UIViewController {}

// MARK: - Supporting

enum DetailView<T: UIViewController> {
    case visible(T)
    case empty
}

// MARK: - Class

class NavigationController: UINavigationController {

    var detailView: DetailView<UIViewController> = .empty

    // MARK: - A

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        log.debug("\(#function) : \(String(describing: viewController.self))")
        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        log.debug("\(#function) : \(String(describing: topViewController.self))")
        if case .visible(let detailViewController) = detailView {
            if topViewController === detailViewController {
                log.debug("\(#function) : POPPED DETAIL")
                detailView = .empty
            } else {
                log.warning("\(#function) FAILED : tried to pop wrong view controller")
                /// TODO: call `setViewControllers([emptyDetailViewController], animated: true)` on detailViewController
            }
        } else {
            log.debug("\(#function) : POPPED OTHER")
        }
        return super.popViewController(animated: animated)
    }

    // MARK: - B

    func separate() {
        //log.debug("\(#function)")
        switch detailView {
        case .visible:
            viewControllers = Array(viewControllers.dropLast())
        case .empty:
            return
        }
    }

    func collapse() {
        //log.debug("\(#function)")
        switch detailView {
        case .visible(let detailViewController):
            viewControllers = viewControllers + [detailViewController]
        case .empty:
            return
        }
    }

}
