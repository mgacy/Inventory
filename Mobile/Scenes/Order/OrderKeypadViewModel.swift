//
//  OrderKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

class OrderKeypadViewModel: KeypadViewModel {

    private let managedObjectContext: NSManagedObjectContext
    private let numberFormatter: NumberFormatter
    private var currentItemUnits: ItemUnits
    private var parentObject: Order

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
    internal var currentIndex: Int

    public var currentUnit: CurrentUnit? {
        return currentItemUnits.currentUnit
    }

    // MARK: Keypad
    internal let keypad: Keypad
    //internal var keypad: KeypadType

    // MARK: - X

    // Display
    var orderQuantity: String = ""
    var name: String {
        return currentItem.item?.name ?? "Error (2)"
    }
    var orderUnit: String {
        return currentItem.orderUnit?.abbreviation ?? ""
    }
    var pack: String {
        return currentItem.item?.packDisplay ?? ""
    }
    var par: String {
        guard currentItem.par >= 0 else {
            return "--"
        }
        return formDisplayLine(quantity: currentItem.par,
                               abbreviation: currentItem.parUnit?.abbreviation)
    }
    var onHand: String {
        guard currentItem.onHand >= 0 else {
            return "--"
        }
        return formDisplayLine(quantity: currentItem.onHand,
                               abbreviation: currentItem.item?.inventoryUnit?.abbreviation)
    }
    var suggestedOrder: String {
        guard currentItem.minOrder >= 0 else {
            return "--"
        }
        return formDisplayLine(quantity: currentItem.minOrder,
                               abbreviation: currentItem.minOrderUnit?.abbreviation)
    }

    // Keypad
    var singleUnitLabel: String {
        return currentItemUnits.singleUnit?.abbreviation ?? ""
    }
    var singleUnitIsEnabled: Bool = true
    var singleUnitIsActive: Bool = false
    var packUnitLabel: String {
        return currentItemUnits.packUnit?.abbreviation ?? ""
    }
    var packUnitIsEnabled: Bool = true
    var packUnitIsActive: Bool = false

    // MARK: - Lifecycle

    required init(for order: Order, atIndex index: Int, inContext context: NSManagedObjectContext) {
        self.parentObject = order
        self.currentIndex = index
        self.managedObjectContext = context
        self.currentItemUnits = ItemUnits(item: nil, currentUnit: nil)

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        self.numberFormatter = numberFormatter

        // Keypad
        self.keypad = Keypad(formatter: numberFormatter, delegate: nil)
        // We can only set the keypad's delegate after we have set all required attrs for self
        keypad.delegate = self

        self.didChangeItem(self.currentItem)
    }

    // MARK: - Actions from View Controller

    // rename `changeUnit`; return `CurrentUnit`?
    func switchUnit(_ newUnit: CurrentUnit) -> Bool {
        guard let newUnit = currentItemUnits.switchUnit(newUnit) else {
            log.warning("\(#function) FAILED")
            return false
        }
        currentItem.orderUnit = newUnit
        /// TODO: save context?
        return true
    }

    // MARK: -

    internal func didChangeItem(_ currentItem: OrderItem) {
        currentItemUnits = ItemUnits(item: currentItem.item, currentUnit: currentItem.orderUnit)

        // Update keypad with quantity of new currentItem
        keypad.updateNumber(currentItem.quantity)
        orderQuantity = keypad.displayValue
    }

    // MARK: - Formatting

    private func formDisplayLine(quantity: Double?, abbreviation: String?) -> String {
        guard let quantity = quantity else { return "ERROR 4" }
        if let quantityString = numberFormatter.string(from: NSNumber(value: quantity)) {
            return "\(quantityString) \(abbreviation ?? "")"
        }
        return ""
    }

}

// MARK: - Keypad
/// TODO: simply move to default implementation of KeypadStuff?
extension OrderKeypadViewModel: KeypadProxy {

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

extension OrderKeypadViewModel: KeypadDelegate {

    func updateModel(_ newValue: NSNumber?) {
        if let newValue = newValue {
            currentItem.quantity = newValue
            orderQuantity = keypad.displayValue
        } else {
            currentItem.quantity = 0
            orderQuantity = "0"
        }
        managedObjectContext.performSaveOrRollback()
    }

}
