//
//  UITableViewController+Alert.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController {

    // If we pass a handler, display a "Cancel" and an "OK" button with the latter calling that handler
    // Otherwise, display a single "OK" button
    /// TODO: shouldn't we allow the specification of the okAction's title?
    /// TODO: should we just present the alert within the function instead of returning it?
    func createAlert(title: String, message: String, handler: (() -> Void)? = nil) -> UIAlertController {

        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            // swiftlint:disable:next unused_closure_parameter
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        return alert
    }

    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {

        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            // swiftlint:disable:next unused_closure_parameter
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

}
