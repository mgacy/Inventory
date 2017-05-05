//
//  UIView+Magic.swift
//  Magic
//  https://github.com/SwiftyMagic/Magic
//
//  Created by Broccoli on 16/9/12.
//  Copyright © 2016年 broccoliii. All rights reserved.
//

import Foundation
import UIKit
/*
fileprivate var ActivityIndicatorViewAssociativeKey = "ActivityIndicatorViewAssociativeKey"
public extension UIView {

    var activityIndicatorView: UIActivityIndicatorView {
        get {
            if let activityIndicatorView = getAssociatedObject(&ActivityIndicatorViewAssociativeKey) as? UIActivityIndicatorView {
                return activityIndicatorView
            } else {
                let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                activityIndicatorView.activityIndicatorViewStyle = .gray
                activityIndicatorView.color = .gray
                activityIndicatorView.center = center
                activityIndicatorView.hidesWhenStopped = true
                addSubview(activityIndicatorView)

                setAssociatedObject(activityIndicatorView, associativeKey: &ActivityIndicatorViewAssociativeKey, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return activityIndicatorView
            }
        }

        set {
            addSubview(newValue)
            setAssociatedObject(newValue, associativeKey:&ActivityIndicatorViewAssociativeKey, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setupActivityIndicator(style: UIActivityIndicatorViewStyle, color: UIColor) {
        activityIndicatorView.activityIndicatorViewStyle = style
        activityIndicatorView.color = color
    }

}
*/
/*
 
 /// NOTE: this version was causing problems with the indicator failing to be dismissed when .stopAnimating() was called

fileprivate var ActivityIndicatorViewAssociativeKey = "ActivityIndicatorViewAssociativeKey"
public extension UIView {

    var activityIndicatorView: UIActivityIndicatorView {
        get {
            guard let activityIndicatorView = getAssociatedObject(ActivityIndicatorViewAssociativeKey) as? UIActivityIndicatorView else {

                let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                activityIndicatorView.activityIndicatorViewStyle = .gray
                activityIndicatorView.color = .gray
                activityIndicatorView.center = center
                //activityIndicatorView.frame.y = activityIndicatorView.frame.y - 40
                activityIndicatorView.hidesWhenStopped = true
                addSubview(activityIndicatorView)

                setAssociatedObject(activityIndicatorView, associativeKey: &ActivityIndicatorViewAssociativeKey, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return activityIndicatorView
            }
            return activityIndicatorView
        }

        set {
            addSubview(newValue)
            setAssociatedObject(newValue, associativeKey:&ActivityIndicatorViewAssociativeKey, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setupActivityIndicator(style: UIActivityIndicatorViewStyle, color: UIColor) {
        activityIndicatorView.activityIndicatorViewStyle = style
        activityIndicatorView.color = color
    }

}
*/
