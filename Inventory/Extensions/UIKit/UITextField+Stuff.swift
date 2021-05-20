//
//  UITextField+Stuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/14/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

extension UITextField {

    enum Direction {
        case left
        case right
    }

    func addButton(button: UIButton, direction: Direction) {
        let padding = 8
        let size = Int(button.frame.width)
        let outerView = UIView(frame: CGRect(x: 0, y: 0, width: size + padding, height: size) )
        outerView.addSubview(button)

        switch direction {
        case .left:
            self.leftViewMode = .always
            self.leftView = outerView
        case .right:
            self.rightViewMode = .always
            self.rightView = outerView
        }
    }

}
