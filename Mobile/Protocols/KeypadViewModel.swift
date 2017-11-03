//
//  KeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

/// TODO: rename ItemListViewModelType?
protocol KeypadViewModel: class {
    //associatedtype ParentType
    associatedtype ChildType: NSManagedObject

    //var managedObjectContext: NSManagedObjectContext { get set }
    //var parentObject: ParentType { get set }
    var items: [ChildType] { get }
    var currentIndex: Int { get set }
    var currentItem: ChildType { get }

    func nextItem() -> Bool
    func previousItem() -> Bool
    func didChangeItem(_: ChildType)
}

// MARK: - Default Implementation

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

// MARK: - NEW

/// TODO: rename `ListProxy`?
// In practice, use of this relies on `didSet` on `currentIndex` which calls `didChangeItem(currentItem)`
protocol ListViewModelType {
    associatedtype ItemType

    var items: [ItemType] { get }
    var currentItem: ItemType { get }
    var currentIndex: Int { get set }

    func nextItem() -> Bool
    func previousItem() -> Bool
    //func didChangeItem(_: ItemType)
}

extension ListViewModelType {

    var currentItem: ItemType {
        return items[currentIndex]
    }

    mutating func nextItem() -> Bool {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

    mutating func previousItem() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

}

// We don't want to expose the Keypad directly to the view controller, so they will interact with view models conforming
// to this protocol instead
protocol KeypadProxy: class {
    //var keypad: KeypadType { get }
    func pushDigit(value: Int)
    func pushDecimal()
    func popItem()
}
/*
extension KeypadProxy {

    func pushDigit(value: Int) {
        keypad.pushDigit(value)
    }

    func pushDecimal() {
        keypad.pushDecimal()
    }

    func popItem() {
        keypad.popItem()
    }

}
*/
protocol KeypadWithHistoryProxy {
    //var keypad: KeypadWithHistoryType { get }
    func pushDigit(value: Int)
    func pushDecimal()
    func pushOperator()
    func popItem()
}
/*
extension KeypadWithHistoryProxy {

    func pushDigit(value: Int) {
        keypad.pushDigit(value)
    }

    func pushDecimal() {
        keypad.pushDecimal()
    }

    func popItem() {
        keypad.popItem()
    }

    func pushOperator() {
        keypad.pushOperator()
    }

}
*/
