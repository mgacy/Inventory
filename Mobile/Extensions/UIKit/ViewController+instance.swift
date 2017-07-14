//
//  ViewController+instance.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/22/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

// https://medium.cobeisfresh.com/a-case-for-using-storyboards-on-ios-3bbe69efbdf4

import UIKit

extension UIViewController {
    class func instance() -> Self? {
        let storyboardName = String(describing: self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.initialViewController()
    }
}

extension UIStoryboard {
    func initialViewController<T: UIViewController>() -> T? {
        return self.instantiateInitialViewController() as? T
    }
}
