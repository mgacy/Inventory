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

    // MARK: Mode
    enum KeypadState {
        case cost
        case quantity
        case status

        // TODO: include relevant methods?

        // TODO: return new state?
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

    private let dataManager: DataManager
    private let managedObjectContext: NSManagedObjectContext
    private let numberFormatter: NumberFormatter
    private let currencyFormatter: NumberFormatter
    private var currentItemUnits: ItemUnits
    private var parentObject: Invoice

    internal var currentIndex: Int
    internal let keypad: Keypad
    //internal var keypad: KeypadType

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

    var currentMode: KeypadState = .cost

    // MARK: - X

    // Display

    var itemName: String {
        return currentItem.item?.name ?? "Error (1)"
    }
    var itemPack: String {
        return currentItem.item?.packDisplay ?? "Error (2)"
    }
    var itemCost: String {
        return currencyFormatter.string(from: NSNumber(value: currentItem.cost)) ?? " "
    }
    var itemQuantity: String {
        return numberFormatter.string(from: NSNumber(value: currentItem.quantity)) ?? "Error (3)"
    }
    public var currentUnit: CurrentUnit? {
        return currentItemUnits.currentUnit
    }
    var itemStatus: String {
        return InvoiceItemStatus(rawValue: currentItem.status)?.description ?? ""
    }

    // Keypad
    var unitButtonTitle: String = ""

    // MARK: - Lifecycle

    // TODO: pass DataManager
    required init(dataManager: DataManager, for invoice: Invoice, atIndex index: Int) {
        self.dataManager = dataManager
        self.parentObject = invoice
        self.currentIndex = index
        self.managedObjectContext = dataManager.managedObjectContext
        self.currentItemUnits = ItemUnits(item: nil, currentUnit: nil)

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        self.numberFormatter = numberFormatter

        // Setup currencyFormatter
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        self.currencyFormatter = currencyFormatter

        // Keypad
        self.keypad = Keypad(formatter: numberFormatter, delegate: nil)
        // We can only set the keypad's delegate after we have set all required attrs for self
        keypad.delegate = self

        self.didChangeItem(self.currentItem)
    }

    // MARK: - Actions from View Controller

    public func switchMode(_ newMode: KeypadState) {
        currentMode = newMode

        switch newMode {
        case .cost:
            keypad.updateNumber(currentItem.cost as NSNumber)
        case .quantity:
            keypad.updateNumber(currentItem.quantity as NSNumber)
        case .status:
            break
        }
    }

    func toggleUnit() -> Bool {
        guard let newUnit = currentItemUnits.toggle() else {
            return false
        }
        currentItem.unit = newUnit
        // TODO: save context?

        guard let currentUnit = currentItemUnits.currentUnit else {
            // TODO: what should the label be in this situation?
            unitButtonTitle = "?"
            return true
        }
        // We want the label to be the inactive unit
        switch currentUnit {
        case .singleUnit:
            unitButtonTitle = currentItemUnits.packUnit?.abbreviation ?? ""
            // TODO: disable softButton if .packUnit is nil?
        case .packUnit:
            unitButtonTitle = currentItemUnits.singleUnit?.abbreviation ?? ""
        case .invalidUnit:
            unitButtonTitle = "ERR"
        }

        return true
    }

    // MARK: -

    internal func didChangeItem(_ currentItem: InvoiceItem) {

        // Handle purchaseUnit, purchaseSubUnit
        currentItemUnits = ItemUnits(item: currentItem.item, currentUnit: currentItem.unit)

        // TODO: this would be a good place to use an associated value w/ the enum
        if let currentUnit = currentUnit {
            switch currentUnit {
            case .singleUnit:
                unitButtonTitle = currentItemUnits.packUnit?.abbreviation ?? ""
            case .packUnit:
                unitButtonTitle = currentItemUnits.singleUnit?.abbreviation ?? ""
            case .invalidUnit:
                unitButtonTitle = "ERR"
            }
        } else {
            // TODO: is there a better way to handle this?
            unitButtonTitle = "ERR"
        }

        switchMode(.cost)
    }

}

extension InvoiceKeypadViewModel: DisplayItemViewModelType {}

// MARK: - Keypad
extension InvoiceKeypadViewModel: KeypadProxy {

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

}

extension InvoiceKeypadViewModel: KeypadDelegate {

    func updateModel(_ newValue: NSNumber?) {
        switch currentMode {
        case .cost:
            if let newValue = newValue {
                currentItem.cost = newValue.doubleValue
                //currentItem.cost = Double(truncating: newValue)
            } else {
                currentItem.cost = 0
            }
        case .quantity:
            if let newValue = newValue {
                currentItem.quantity = newValue.doubleValue
                //currentItem.quantity = Double(truncating: newValue)
            } else {
                currentItem.quantity = 0
            }
        case .status:
            log.verbose("update - status")
        }
        managedObjectContext.performSaveOrRollback()
    }

}
