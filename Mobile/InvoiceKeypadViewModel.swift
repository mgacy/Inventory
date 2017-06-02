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

    // MARK: Keypad
    let keypad: NewKeypad

    var numberFormatter: NumberFormatter
    var currencyFormatter: NumberFormatter

    /// TODO: include relevant methods within this?
    enum KeypadState {
        case quantity
        case cost
        case status
    }

    /// TODO: should default mode be cost, since that is most likely to vary?
    var currentMode: KeypadState = .quantity

    // MARK: X

    // Display
    var itemName: String = ""
    var itemQuantity: String = ""
    var itemCost: String = ""
    var itemStatus: String = ""
    var displayQuantity: String = ""

    // Keypad
    var softButtonTitle: String = ""
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
        /// TODO: make `InvoiceItem.item` non-optional
        guard let item = currentItem.item else {
            // fatalError("FIXME")
            itemName = "Error (1)"; return
        }
        guard let name = item.name else {
            itemName = "Error (2)" ; return
        }
        itemName = name

        currentMode = .quantity
        keypad.updateNumber(currentItem.quantity as NSNumber)

        // Get strings for display
        displayQuantity = formDisplayLine(
            quantity: keypad.displayValue,
            abbreviation: currentItem.unit?.abbreviation)

        itemQuantity = displayQuantity
        itemCost = currencyFormatter.string(from: NSNumber(value: currentItem.cost)) ?? " "
        if let statusString = InvoiceItemStatus(rawValue: currentItem.status)?.description {
            itemStatus = statusString
        } else {
            itemStatus = ""
        }
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

    /*
    func formDisplayLine(quantity: Double?, abbreviation: String?) -> String {
        guard let quantity = quantity else { return "ERROR 4" }

        // Quantity
        if let quantityString = numberFormatter.string(from: NSNumber(value: quantity)) {
            return "\(quantityString) \(abbreviation)"
        }
        return ""
    }
    */

}

// MARK: - Keypad
extension InvoiceKeypadViewModel: KeypadStuff {

    func pushDigit(value: Int) {
        if currentMode == .status { return }
        keypad.pushDigit(value: value)
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
