//
//  NSLayoutAnchor+Ext.swift
//  Mobile
//
//  Source:
//  https://stackoverflow.com/a/39111696/4472195
//
//  Created by Mathew Gacy on 5/17/18.
//

import UIKit

extension NSLayoutXAxisAnchor {
    func constraintEqualToAnchor(anchor: NSLayoutXAxisAnchor, constant: CGFloat, identifier: String) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor, constant: constant)
        constraint.identifier = identifier
        return constraint
    }
}

extension NSLayoutYAxisAnchor {
    func constraintEqualToAnchor(anchor: NSLayoutYAxisAnchor, constant: CGFloat, identifier: String) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor, constant: constant)
        constraint.identifier = identifier
        return constraint
    }
}

extension NSLayoutDimension {
    func constraintEqualToAnchor(anchor: NSLayoutDimension, constant: CGFloat, identifier: String) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor, constant: constant)
        constraint.identifier = identifier
        return constraint
    }
}

extension UIView {
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
}
