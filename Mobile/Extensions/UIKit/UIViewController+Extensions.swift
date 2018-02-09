//
//  UIViewController+Extensions.swift
//  Mobile
//
//  Created by Mathew Gacy on 2/8/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

// Based on:
// https://www.swiftbysundell.com/posts/using-child-view-controllers-as-plugins-in-swift
extension UIViewController {

    func add(_ child: UIViewController, with layoutConstraints: [NSLayoutConstraint]? = nil) {
        addChildViewController(child)
        view.addSubview(child.view)

        if let constraints = layoutConstraints {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(constraints)
        }

        child.didMove(toParentViewController: self)
    }

    func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParentViewController: nil)
        removeFromParentViewController()
        view.removeFromSuperview()
    }
}
