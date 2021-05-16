//
//  UIAlertControllerStyle+Adaptive.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/17.
//
//  From:
//  Jordan Smith
//  http://jordansmith.io/creating-a-dynamic-uialertviewcontrollerstyle/
//

import UIKit

extension UIAlertControllerStyle {
    static var adaptiveActionSheet: UIAlertControllerStyle {
        return UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
    }
}
