//
//  OrderKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Units

/// TODO: use abbreviation as associated value?
enum CurrentUnit {
    case packUnit
    case singleUnit
    case invalidUnit
}

struct ItemUnits {
    var packUnit: Unit?
    var singleUnit: Unit?
    var currentUnit: CurrentUnit?

    init(item: Item?, currentUnit: Unit?) {
        guard let item = item else {
            return
        }

        self.packUnit = item.purchaseUnit
        self.singleUnit = item.purchaseSubUnit

        guard let currentUnit = currentUnit else {
            self.currentUnit = nil
            return
        }

        if let pUnit = self.packUnit, currentUnit == pUnit {
            self.currentUnit = .packUnit
        } else if let sUnit = self.singleUnit, currentUnit == sUnit {
            self.currentUnit = .singleUnit
        } else {
            self.currentUnit = .invalidUnit
        }
    }

    public mutating func switchUnit(_ newUnitCase: CurrentUnit) -> Unit? {
        guard newUnitCase != currentUnit else {
            log.debug("\(#function) FAILED: tried to switchUnit to currentUnit")
            return nil
        }
        switch newUnitCase {
        case .singleUnit:
            guard let newUnit = singleUnit else {
                return nil
            }
            currentUnit = .singleUnit
            return newUnit
        case .packUnit:
            guard let newUnit = packUnit else {
                return nil
            }
            currentUnit = .packUnit
            return newUnit
        default:
            log.error("\(#function)) FAILED: tried to switch unit to .invalidUnit")
            return nil
        }
    }

    public mutating func toggle() -> Unit? {
        guard let currentUnitCase = self.currentUnit else {
            /// TODO: can we somehow still change the unit?
            return nil
        }

        switch currentUnitCase {
        case .singleUnit:
            guard let newUnit = packUnit else {
                return nil
            }
            currentUnit = .packUnit
            return newUnit
        case .packUnit:
            guard let newUnit = singleUnit else {
                return nil
            }
            currentUnit = .singleUnit
            return newUnit
        case .invalidUnit:
            log.error("\(#function) FAILED: currentUnit.invalidUnit")

            if let newUnit = packUnit {
                currentUnit = .packUnit
                return newUnit
            } else if let newUnit = singleUnit {
                currentUnit = .singleUnit
                return newUnit
            }
            return nil
        }
    }

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

    private var currentItemUnits: ItemUnits
    public var currentUnit: CurrentUnit? {
        return currentItemUnits.currentUnit
    }

    // MARK: Keypad
    let keypad: Keypad

    var numberFormatter: NumberFormatter

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
        /// TODO: do I even need this anymore?
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.roundingMode = .halfUp
        self.numberFormatter.maximumFractionDigits = 2

        // Keypad
        let keypadFormatter = NumberFormatter()
        keypadFormatter.numberStyle = .decimal
        keypadFormatter.roundingMode = .halfUp
        keypadFormatter.maximumFractionDigits = 2
        self.keypad = Keypad(formatter: keypadFormatter, delegate: nil)
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
extension OrderKeypadViewModel: KeypadStuff {

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
