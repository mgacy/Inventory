//
//  OrderKeypadViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

class OrderKeypadViewModel {

    private let managedObjectContext: NSManagedObjectContext
    private let numberFormatter: NumberFormatter
    private var currentItemUnits: ItemUnits
    //private var dataSource: ListDataSource
    internal var items: [OrderItem] = []

    internal var currentIndex: Int {
        didSet {
            didChangeItem(currentItem)
        }
    }

    internal var keypad: KeypadType

    // Public

    var currentItem: OrderItem {
        //return dataSource.getItem(atIndex: currentIndex)!
        return items[currentIndex]
    }

    public var currentUnit: CurrentUnit? {
        return currentItemUnits.currentUnit
    }

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

    convenience init(for order: Order, atIndex index: Int, inContext context: NSManagedObjectContext) {
        self.init(atIndex: index, in: context)
        self.items = self.getItems(for: order, in: context)
        //self.dataSource = CDOrderItemDataSource(for: order, inContext: context)
        self.didChangeItem(self.currentItem)
    }

    convenience init(with items: [OrderItem], atIndex index: Int, in context: NSManagedObjectContext) {
        self.init(atIndex: index, in: context)
        self.items = items
        //self.dataSource = RROrderItemDataSource(for: parent, factory: factory)
        self.didChangeItem(self.currentItem)
    }

    private init(atIndex index: Int, in context: NSManagedObjectContext) {
        self.managedObjectContext = context
        self.currentItemUnits = ItemUnits(item: nil, currentUnit: nil)
        self.currentIndex = index

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
    }

    private func getItems(for order: Order, in managedObjectContext: NSManagedObjectContext) -> [OrderItem] {
        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.predicate = NSPredicate(format: "order == %@", order)

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

extension OrderKeypadViewModel: ListViewModelType {

    func nextItem() -> Bool {
        //if currentIndex < dataSource.length - 1 {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

    func previousItem() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            return true
        } else {
            /// TODO: cleanup?
            return false
        }
    }

}

// MARK: - Keypad
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
/*
// MARK: - Alternative Approach

// It appears that implementing this would require type erasure

protocol ListDataSource {
    associatedtype ItemType

    var items: [ItemType] { get }
    var length: Int { get }

    //mutating func addItem(_: ItemType)
    func getItem(atIndex: Int) -> ItemType?
}

extension ListDataSource {
    var length: Int {
        return items.count
    }

    func getItem(atIndex index: Int) -> ItemType? {
        return items[index]
    }

}

// MARK: Implementation

class RROrderItemDataSource: ListDataSource {
    //private let factory: OrderLocationFactory
    var items: [OrderItem]

    init(for parent: OrderLocItemParent, factory: OrderLocationFactory) {
        //self.factory = factory
        switch parent {
        case .category(let category):
            self.items = factory.getOrderItems(forCategoryType: category) ?? []
        case .location(let location):
            self.items = factory.getOrderItems(forItemType: location) ?? []
        }
    }
}

class CDOrderItemDataSource: ListDataSource {
    private var managedObjectContext: NSManagedObjectContext
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

    init(for order: Order, inContext context: NSManagedObjectContext) {
        self.parentObject = order
        self.managedObjectContext = context
    }

}
*/
