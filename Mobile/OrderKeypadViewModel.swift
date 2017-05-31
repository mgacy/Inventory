//
//  OrderKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocol
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
    //func updateCurrentItem()
}

extension KeypadViewModel {

    var currentItem: ChildType {
        //log.verbose("currentItem: \(items[currentIndex])")
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
    var keypad: Keypad { get }
    func pushDigit(_: Int)
    func pushDecimal()
    func popItem()
    //func update(_: Double?)
}

// MARK: - Actual
class OrderKeypadViewModel: KeypadViewModel {

    var managedObjectContext: NSManagedObjectContext
    var parentObject: Order
    var items: [OrderItem] {
        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.predicate = NSPredicate(format: "order == %@", parentObject)

        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        do {
            let searchResults = try managedObjectContext.fetch(request)
            return searchResults

        } catch {
            log.error("Error with request: \(error)")
        }
        return [OrderItem]()
    }
    var currentIndex: Int

    // MARK: Keypad
    let keypad: Keypad

    var numberFormatter: NumberFormatter

    // MARK: X

    // Display
    var name: String = ""
    var orderQuantity: String = ""
    var orderUnit: String = ""
    var pack: String = ""
    var par: String = ""
    var onHand: String = ""
    var suggestedOrder: String = ""
    // Keypad
    var singleUnitLabel: String = ""
    var packUnitLabel: String = ""
    // ???
    // purchaseUnit: Unit?
    // purchaseSubUnit: Unit?
    // ???

    // MARK: - Lifecycle

    required init(for order: Order, atIndex index: Int, inContext context: NSManagedObjectContext) {
        self.parentObject = order
        self.currentIndex = index
        self.managedObjectContext = context

        // Setup numberFormatter
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.roundingMode = .halfUp
        self.numberFormatter.maximumFractionDigits = 2

        self.keypad = Keypad()

        self.didChangeItem(self.currentItem)
    }

    // MARK: -

    /// TODO: pass unit or simply toggle unit?
    //func updateUnit(_ unit: Unit) {}

    //func toggleUnit() {}

    //func updateQuantity(_ quantity: Double) {}

    // MARK: -

    internal func didChangeItem(_ currentItem: OrderItem) {
        /// TODO: make `OrderItem.item` non-optional
        guard let item = currentItem.item else {
            // fatalError("FIXME")
            name = "Error (1)"
            return
        }
        name = item.name ?? "Error (2)"
        pack = item.packDisplay

        /// TODO: handle purchaseUnit, purchaseSubUnit

        par = formDisplayLine(
            quantity: currentItem.par, abbreviation: currentItem.parUnit?.abbreviation ?? " ")
        onHand = formDisplayLine(
            quantity: currentItem.onHand, abbreviation: currentItem.item?.inventoryUnit?.abbreviation ?? " ")
        suggestedOrder = formDisplayLine(
            quantity: currentItem.minOrder, abbreviation: currentItem.minOrderUnit?.abbreviation ?? " ")
        orderUnit = currentItem.orderUnit?.abbreviation ?? " "

        // ... keypad ...

        // Update keypad with quantity of new currentItem
        keypad.updateNumber(currentItem.quantity as Double?)

        orderQuantity = keypad.display
    }

    func updateItem() {
        // Update model with output of keypad
        if let keypadResult = keypad.evaluateNumber() {
            currentItem.quantity = keypadResult as NSNumber?
        } else {
            currentItem.quantity = nil
        }
        managedObjectContext.performSaveOrRollback()

        /// TODO: update display
        /// TODO: update keypad
    }

    // MARK: -

    private func formDisplayLine(quantity: Double?, abbreviation: String) -> String {
        guard let quantity = quantity else { return "ERROR 4" }

        // Quantity
        if let quantityString = numberFormatter.string(from: NSNumber(value: quantity)) {
            return "\(quantityString) \(abbreviation)"
        }
        return ""
    }

}

// MARK: - Keypad
extension OrderKeypadViewModel {

    func pushDigit(value: Int) {
        //currentItem.quantity = keypad.pushDigit(value: value)
        keypad.pushDigit(value: value)
    }

    func pushDecimal() {
        //currentItem.quantity = keypad.pushDecimal()
        keypad.pushDecimal()
    }

    func popCharacter() {
        //currentItem.quantity = keypad.popItem()
        keypad.popItem()
    }

    func reset(with number: Double?) {
        keypad.updateNumber(number)
    }

}
