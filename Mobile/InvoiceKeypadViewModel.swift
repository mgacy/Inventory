//
//  InvoiceKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/31/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

class InvoiceKeypadViewModel: KeypadViewModel {

    var managedObjectContext: NSManagedObjectContext
    var parentObject: Invoice
    var items: [InvoiceItem] {
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        request.predicate = NSPredicate(format: "invoice == %@", parentObject)

        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        do {
            let searchResults = try managedObjectContext.fetch(request)
            return searchResults

        } catch {
            log.error("Error with request: \(error)")
        }
        return [InvoiceItem]()
    }
    var currentIndex: Int

    // MARK: Units
    private var currentItemUnits: ItemUnits?
    public var currentUnit: CurrentUnit {
        guard let current = currentItemUnits else {
            return .error
        }
        return current.currentUnit
    }

    // MARK: Keypad
    let keypad: NewKeypad

    var numberFormatter: NumberFormatter
    var currencyFormatter: NumberFormatter

    // MARK: Mode
    enum KeypadState {
        case cost
        case quantity
        case status

        /// TODO: include relevant methods?

        /// TODO: return new state?
        mutating func next() {
            switch self {
            case .cost:
                self = .quantity
            case .quantity:
                self = .status
            case .status:
                self = .cost
            }
            //return self
        }
    }

    //var currentMode: KeypadState = .quantity
    var currentMode: KeypadState = .cost

    // MARK: X

    // Display
    var itemName: String = ""
    var itemQuantity: String = ""
    var itemCost: String = ""
    var itemStatus: String = ""
    var displayQuantity: String = ""

    // Keypad
    var softButtonTitle: String = "m"
    var unitButtonTitle: String = ""

    // MARK: - Lifecycle

    required init(for invoice: Invoice, atIndex index: Int, inContext context: NSManagedObjectContext) {
        self.parentObject = invoice
        self.currentIndex = index
        self.managedObjectContext = context

        // Setup numberFormatter
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2

        // Setup currencyFormatter
        currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency

        // Keypad
        let keypadFormatter = NumberFormatter()
        keypadFormatter.numberStyle = .decimal
        keypadFormatter.roundingMode = .halfUp
        keypadFormatter.maximumFractionDigits = 2
        self.keypad = NewKeypad(formatter: keypadFormatter, delegate: nil)
        // We can only set the keypad's delegate after we have set all required attrs for self
        keypad.delegate = self

        self.didChangeItem(self.currentItem)
    }

    // MARK: -

    internal func didChangeItem(_ currentItem: InvoiceItem) {

        // Handle purchaseUnit, purchaseSubUnit
        currentItemUnits = ItemUnits(item: currentItem.item, currentUnit: currentItem.unit)

        /// TODO: this would be a good place to use an associated value w/ the enum
        switch currentUnit {
        case .singleUnit:
            unitButtonTitle = currentItemUnits?.packUnit?.abbreviation ?? ""
        case .packUnit:
            unitButtonTitle = currentItemUnits?.singleUnit?.abbreviation ?? ""
        case .error:
            unitButtonTitle = "ERR"
        }

        // Get strings for display
        itemName = currentItem.item?.name ?? "Error (1)"
        itemCost = currencyFormatter.string(from: NSNumber(value: currentItem.cost)) ?? " "
        itemQuantity = formDisplayLine(
            quantity: currentItem.quantity,
            abbreviation: currentItem.unit?.abbreviation)
        itemStatus = InvoiceItemStatus(rawValue: currentItem.status)?.description ?? ""

        switchMode(.cost)
        //switchMode(.quantity)
    }

    // MARK: -

    func switchMode(_ newMode: KeypadState) {
        currentMode = newMode

        switch newMode {
        case .cost:
            keypad.updateNumber(currentItem.cost as NSNumber)
            displayQuantity = keypad.displayValue
        case .quantity:
            keypad.updateNumber(currentItem.quantity as NSNumber)
            displayQuantity = keypad.displayValue
        case .status:
            if let statusString = InvoiceItemStatus(rawValue: currentItem.status)?.description {
                displayQuantity = statusString
            } else {
                displayQuantity = ""
            }
        }
    }

    // MARK: -

    func formDisplayLine(quantity: String, abbreviation: String?) -> String {
        //return "\(quantity) \(abbreviation)"
        if let abbreviation = abbreviation {
            return "\(quantity) \(abbreviation)"
        } else {
            return quantity
        }
    }

    func formDisplayLine(quantity: Double?, abbreviation: String?) -> String {
        guard let quantity = quantity else { return "ERROR 4" }

        let quantityString = numberFormatter.string(from: NSNumber(value: quantity)) ?? ""
        if let abbreviation = abbreviation {
            return "\(quantityString) \(abbreviation)"
        } else {
            return quantityString
        }
    }

}

// MARK: - Keypad
extension InvoiceKeypadViewModel: KeypadStuff {

    func pushDigit(value: Int) {
        if currentMode == .status { return }
        keypad.pushDigit(value)
    }

    func pushDecimal() {
        if currentMode == .status { return }
        keypad.pushDecimal()
    }

    func popItem() {
        if currentMode == .status { return }
        keypad.popItem()
    }

    //func reset(with number: NSNumber?) {
    //    keypad.updateNumber(number)
    //}

}

extension InvoiceKeypadViewModel: KeypadDelegate {

    func updateModel(_ newValue: NSNumber?) {
        switch currentMode {
        case .cost:
            if let newValue = newValue {
                currentItem.cost = Double(newValue)
            } else {
                currentItem.cost = 0
            }

            displayQuantity = keypad.displayValue
            itemCost = displayQuantity
        case .quantity:
            if let newValue = newValue {
                currentItem.quantity = Double(newValue)
            } else {
                currentItem.quantity = 0
            }
            displayQuantity = formDisplayLine(
                quantity: keypad.displayValue,
                abbreviation: currentItem.unit?.abbreviation ?? " ")
            itemQuantity = displayQuantity

        case .status:
            /// NOTE: we should not ever reach this case
            log.verbose("update - status")
        }
        managedObjectContext.performSaveOrRollback()
    }

}
