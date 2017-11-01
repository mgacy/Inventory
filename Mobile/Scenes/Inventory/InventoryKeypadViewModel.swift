//
//  InventoryKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/18/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

class InventoryKeypadViewModel: KeypadViewModel {

    var managedObjectContext: NSManagedObjectContext
    internal var parentObject: LocationItemListParent
    internal var currentIndex: Int
    internal var items: [InventoryLocationItem] {
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()

        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        /// TODO: think about [Moving Safety into Types](http://www.figure.ink/blog/2017/10/15/moving-safety-into-types)
        guard let fetchPredicate = parentObject.fetchPredicate else {
            fatalError("\(#function) FAILED : LocationItemListParent not set")
        }
        request.predicate = fetchPredicate
        /*
        switch parentObject {
        case .category(let category):
            request.predicate = NSPredicate(format: "category == %@", category)
        case .location(let location):
            request.predicate = NSPredicate(format: "location == %@", location)
        case .none:
            fatalError("\(#function) FAILED : LocationItemListParent not set")
        }
         */

        do {
            let searchResults = try managedObjectContext.fetch(request)
            return searchResults
        } catch {
            log.error("Error with InventoryLocationItem fetch request: \(error)")
        }
        return [InventoryLocationItem]()
    }

    //private var currentItemUnits: ItemUnits
    //public var currentUnit: CurrentUnit? {
    //    return currentItemUnits.currentUnit
    //}

    // MARK: Keypad
    let keypad: KeypadWithHistory
    //internal var keypad: KeypadWithHistoryType

    private let numberFormatter: NumberFormatter

    // MARK: - X

    // Display
    let itemName = Variable<String>("")
    let itemValue = Variable<String>("")
    let itemValueColor = Variable<UIColor>(.black)
    let itemHistory = Variable<String>("")
    let itemPack = Variable<String>("")
    let itemUnit = Variable<String>("")
    /// TODO: add Observable to pop controller

    // MARK: - Lifecycle

    required init(for parent: LocationItemListParent, atIndex index: Int, inContext context: NSManagedObjectContext) {
        self.parentObject = parent
        self.currentIndex = index
        self.managedObjectContext = context
        //self.currentItemUnits = ItemUnits(item: nil, currentUnit: nil)

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        self.numberFormatter = numberFormatter

        self.keypad = KeypadWithHistory(formatter: numberFormatter)
        // We can only set the keypad's delegate after we have set all required attrs for self
        keypad.delegate = self

        self.didChangeItem(self.currentItem)
    }

    // MARK: - Actions from View Controller

    // MARK: -

    internal func didChangeItem(_ currentItem: InventoryLocationItem) {
        //currentItemUnits = ItemUnits(item: currentItem.item, currentUnit: currentItem.orderUnit)

        // Update keypad with quantity of new currentItem
        keypad.updateNumber(currentItem.quantity)
        if currentItem.quantity != nil {
            itemValueColor.value = UIColor.black
        } else {
            itemValueColor.value = UIColor.lightGray
        }
        itemValue.value = keypad.displayValue
        itemHistory.value = keypad.displayHistory

        guard let item = currentItem.item?.item else {
            log.error("Unable to get Item associated with \(currentItem)"); return
        }
        itemName.value = item.name ?? "Error (1)"
        itemPack.value = item.packDisplay
        itemUnit.value = item.inventoryUnit?.abbreviation ?? ""
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
extension InventoryKeypadViewModel: KeypadWithHistoryProxy {

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

extension InventoryKeypadViewModel: KeypadDelegate {

    func updateModel(_ newValue: NSNumber?) {
        if let newValue = newValue {
            currentItem.quantity = newValue
            itemValue.value = keypad.displayValue
            itemValueColor.value = UIColor.black
            itemHistory.value = keypad.displayHistory
        } else {
            currentItem.quantity = nil
            itemValue.value = keypad.displayValue
            itemValueColor.value = UIColor.lightGray
            itemHistory.value = keypad.displayHistory
        }
        managedObjectContext.performSaveOrRollback()
    }

}
