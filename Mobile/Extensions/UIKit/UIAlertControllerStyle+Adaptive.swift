//
//  UIAlertControllerStyle+Adaptive.swift
//  Mobile
//
//  Jordan Smith
//  http://jordansmith.io/creating-a-dynamic-uialertviewcontrollerstyle/
//
//  Created by Mathew Gacy on 10/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

//import Foundation
import UIKit

extension UIAlertControllerStyle {
    static var adaptiveActionSheet: UIAlertControllerStyle {
        return UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
    }
}
