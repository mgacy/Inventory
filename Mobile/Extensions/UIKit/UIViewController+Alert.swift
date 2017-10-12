//
//  UIViewController+Alert.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import UIKit
import PKHUD

extension UIViewController {

    // If we pass a handler, display a "Cancel" and an "OK" button with the latter calling that handler
    // Otherwise, display a single "OK" button
    /// TODO: shouldn't we allow the specification of the okAction's title?
    /// TODO: should we just present the alert within the function instead of returning it?
    func createAlert(title: String, message: String, handler: (() -> Void)? = nil) -> UIAlertController {

        // Create alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { _ -> Void in
                // Do some stuff
                handler!()
            }
            alertController.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        return alertController
    }

    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {

        // Create alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { _ -> Void in
                // Do some stuff
                handler!()
            }
            alertController.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

}

// MARK: - PKHUD

extension UIViewController {

    func showError(title: String, subtitle: String?, delay: Double = 2.0) {
        PKHUD.sharedHUD.show()
        PKHUD.sharedHUD.contentView = PKHUDErrorView(title: title, subtitle: subtitle)
        PKHUD.sharedHUD.hide(afterDelay: delay)
    }

}

// MARK: - Action Prompt from RxSwift / RxExample

//
//  Wireframe.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 4/3/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

extension UIViewController {

    func promptFor<Action: CustomStringConvertible>(title: String, message: String, cancelAction: Action, actions: [Action]) -> Observable<Action> {

        return Observable.create { [weak self] observer in
            guard let `self` = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
            /// TODO: can we simply set the cancelAction handler to nil / dismiss alertView / observer.onCompleted()?
            alertView.addAction(UIAlertAction(title: cancelAction.description, style: .cancel) { _ in
                observer.on(.next(cancelAction))
            })

            for action in actions {
                alertView.addAction(UIAlertAction(title: action.description, style: .default) { _ in
                    observer.on(.next(action))
                })
            }

            self.present(alertView, animated: true, completion: nil)

            return Disposables.create {
                alertView.dismiss(animated: false, completion: nil)
            }
        }
    }

}
