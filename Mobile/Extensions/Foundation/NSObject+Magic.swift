//
//  NSObject+Magic.swift
//  Magic
//  https://github.com/SwiftyMagic/Magic
//
//  Created by Broccoli on 16/9/13.
//  Copyright © 2016年 broccoliii. All rights reserved.
//
import Foundation

// property
public extension NSObject {
    var className: String {
        return type(of: self).className
    }

    static var className: String {
        return String(describing: self)
    }
}

// function
public extension NSObject {

    func setAssociatedObject(_ value: AnyObject?, associativeKey: UnsafeRawPointer, policy: objc_AssociationPolicy) {
        if let valueAsAnyObject = value {
            objc_setAssociatedObject(self, associativeKey, valueAsAnyObject, policy)
        }
    }

    func getAssociatedObject(_ associativeKey: UnsafeRawPointer) -> Any? {
        guard let valueAsType = objc_getAssociatedObject(self, associativeKey) else {
            return nil
        }
        return valueAsType
    }
}
