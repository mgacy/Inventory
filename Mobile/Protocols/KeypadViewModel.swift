//
//  KeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

protocol KeypadViewModel: class {
    associatedtype ParentType: NSManagedObject
    associatedtype ChildType: NSManagedObject

    var managedObjectContext: NSManagedObjectContext { get set }
    var parentObject: ParentType { get set }
    var items: [ChildType] { get }
    var currentIndex: Int { get set }
    var currentItem: ChildType { get }

    init(for: ParentType, atIndex: Int, inContext: NSManagedObjectContext)
    func nextItem() -> Bool
    func previousItem() -> Bool
    func didChangeItem(_: ChildType)
}

extension KeypadViewModel {

    var currentItem: ChildType {
        return items[currentIndex]
    }

    func nextItem() -> Bool {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            didChangeItem(currentItem)
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

    func previousItem() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            didChangeItem(currentItem)
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

}

protocol KeypadStuff: class {
    var keypad: NewKeypad { get }
    func pushDigit(value: Int)
    func pushDecimal()
    func popItem()
    //func update(_: Double?)
}
