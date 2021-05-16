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

protocol OrderKeypadViewModelType: class {
    var currentItem: OrderItem { get }
    var currentUnit: CurrentUnit? { get }
    /// Display
    var itemName: String { get }
    var itemPack: String { get }
    var orderQuantity: String { get }
    var orderUnit: String { get }
    var par: String { get }
    var onHand: String { get }
    var suggestedOrder: String { get }
    /// Keypad
    var singleUnitLabel: String { get }
    var singleUnitIsEnabled: Bool { get }
    var singleUnitIsActive: Bool { get }
    var packUnitLabel: String { get }
    var packUnitIsEnabled: Bool { get }
    var packUnitIsActive: Bool { get }
    /// Actions from View Controller
    func switchUnit(_ newUnit: CurrentUnit) -> Bool
    func nextItem() -> Bool
    func previousItem() -> Bool
}

// MARK: - ViewModel

class OrderKeypadViewModel: OrderKeypadViewModelType {

    struct Dependency {
        let dataManager: DataManager
        let displayType: OrderDisplayType
        let index: Int
    }

    enum OrderDisplayType {
        case factory([OrderItem])
        case location(OrderLocItemParent)
        case vendor(Order)
    }

    // MARK: - Properties
    private let dataManager: DataManager
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
    var itemName: String {
        return currentItem.item?.name ?? "Error (1)"
    }
    var itemPack: String {
        return currentItem.item?.packDisplay ?? "Error (2)"
    }
    var orderQuantity: String = ""
    var orderUnit: String {
        return currentItem.orderUnit?.abbreviation ?? ""
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

    init(dependency: Dependency) {
        self.dataManager = dependency.dataManager
        self.currentItemUnits = ItemUnits(item: nil, currentUnit: nil)
        self.currentIndex = dependency.index

        // Setup numberFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        self.numberFormatter = numberFormatter

        // Keypad
        self.keypad = Keypad(formatter: numberFormatter, delegate: nil)

        // Items
        //self.dataSource = CDOrderItemDataSource(for: order, inContext: context)
        //self.dataSource = RROrderItemDataSource(for: parent, factory: factory)
        switch dependency.displayType {
        case .factory(let orderItems):
            self.items = orderItems
        case .location(let parent):
            self.items = getItems(forParent: parent, in: dependency.dataManager.managedObjectContext)
        case .vendor(let order):
            self.items = getItems(for: order, in: dependency.dataManager.managedObjectContext)
        }

        /// We can only set the keypad's delegate after we have set all required attrs for self
        keypad.delegate = self
        self.didChangeItem(self.currentItem)
    }

    // MARK: - Build OrderItem List

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

    private func getItems(forParent parent: OrderLocItemParent, in context: NSManagedObjectContext) -> [OrderItem] {
        let request: NSFetchRequest<OrderLocationItem> = OrderLocationItem.fetchRequest()

        switch parent {
        case .category(let category):
            request.predicate = NSPredicate(format: "category == %@", category)
            request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        case .location(let location):
            request.predicate = NSPredicate(format: "location == %@", location)
            request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        }

        do {
            let searchResults = try context.fetch(request)
            return searchResults.flatMap { $0.item }
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
        // TODO: save context?
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
            // TODO: cleanup?
            return false
        }
    }

    func previousItem() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            return true
        } else {
            // TODO: cleanup?
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
        _ = dataManager.saveOrRollback()
        //managedObjectContext.performSaveOrRollback()
    }

}

extension OrderKeypadViewModel: DisplayItemViewModelType {}

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
