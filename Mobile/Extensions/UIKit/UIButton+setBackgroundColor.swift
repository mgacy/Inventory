//
//  UIButton+setBackgroundColor.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

// https://stackoverflow.com/a/30604658
// https://stackoverflow.com/a/39868716
// https://stackoverflow.com/a/47396084
extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let currentGraphicsContext = UIGraphicsGetCurrentContext() {
            currentGraphicsContext.setFillColor(color.cgColor)
            currentGraphicsContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
        //layer.masksToBounds = true
    }
}
