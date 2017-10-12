//
//  InventoriesFactory.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/10/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData

//protocol ModelFactory {}

enum InventoriesFactoryError: Error {
    case recordSerializationFailed(reason: String)
}

class InventoriesFactory {

    // MARK: - Properties

    typealias LocationItemConfig = (InventoryLocationItem, Int32) -> Void

    private let context: NSManagedObjectContext

    // MARK: - Lifecycle

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Create / Update Inventory

    func createNewInventory(from record: RemoteNewInventory, in context: NSManagedObjectContext) -> Inventory? {
        guard let itemDict = try? Item.fetchEntityDict(in: context) else { return nil }
        //guard let categoryDict = try? ItemCategory.fetchEntityDict(in: context) else { return nil }

        // Inventory
        let inventory = createInventory(from: record, in: context)

        // Create InventoryItems
        let inventoryItemDict = record.items.map { record in
            // We use the closure to configure the InventoryItem
            return createInventoryItem(with: record, in: context) { inventoryItem in
                inventoryItem.item = itemDict[record.syncIdentifier]
                inventoryItem.inventory = inventory
            }
        }
        .toDictionary { $0.itemID }
        //log.debug("\(#function) inventoryItemDict: \(inventoryItemDict)")

        // Create InventoryLocations
        /// TODO: can this be cleaned up?
        try? record.locations.forEach { locationRecord in
            do {
                let location = try createLocation(with: locationRecord, in: context) { locationItem, itemID in
                    locationItem.item = inventoryItemDict[itemID]
                }
                location.inventory = inventory
            } catch let error {
                log.error("\(#function) FAILED : \(error)")
                throw error
            }
        }
        return inventory
    }

    public func updateInventory(_ inventory: Inventory, with record: RemoteExistingInventory, in context: NSManagedObjectContext) -> Inventory? {
        log.debug("Updating Inventory: \(inventory) with: \(record)")

        guard let itemDict = try? Item.fetchEntityDict(in: context) else { return nil }
        //guard let unitDict = try? Unit.fetchEntityDict(in: context) else { return nil }

        /// TODO: create default location?
        //let location = InventoryLocation(context: context)

        let predicate = NSPredicate(format: "inventory == %@", inventory)
        // swiftlint:disable:next line_length
        InventoryItem.configurableSync(with: record.items, in: context, matching: predicate) { inventoryItem, remoteRecord in
            //log.debug("Configuring: \(inventoryItem) with: \(remoteRecord)")
            inventoryItem.inventory = inventory
            //inventoryItem.item = itemDict[remoteRecord.item.syncIdentifier]
            let item = itemDict[remoteRecord.item.syncIdentifier]
            inventoryItem.item = item
            inventoryItem.name = item?.name ?? "Error"
            //log.debug("Configured: \(inventoryItem)\n")

            /// TODO: create corresponding InventoryLocationItem and attach to Item, location
            //let locationItem = createLocationItem(itemID: remoteRecord.item.remoteID, position: 0, in: context) { locationItem, itemID in }
            //let locationItem = InventoryLocationItem(context: context)
            //locationItem.item = inventoryItem
            //locationItem.location = location
        }

        return inventory
    }

    // MARK: - Private -

    // MARK: Inventory

    private func createInventory(from record: RemoteNewInventory, in context: NSManagedObjectContext) -> Inventory {
        let inventory = Inventory(context: context)
        // remoteID
        if let date = record.date.toBasicDate() {
            inventory.date = date.timeIntervalSinceReferenceDate
        }
        inventory.storeID = Int32(record.storeID)
        inventory.typeID = Int32(record.inventoryTypeID ?? 0)
        inventory.uploaded = false
        return inventory
    }

    // MARK: InventoryItem

    private func createInventoryItem(with record: RemoteNestedItem, in context: NSManagedObjectContext, configure: (InventoryItem) -> Void) -> InventoryItem {
        let item = InventoryItem(context: context)
        //remoteID
        item.itemID = record.syncIdentifier
        //categoryID
        item.name = record.name

        // Relationships
        //inventory
        //item

        configure(item)
        return item
    }

    // MARK: InventoryLocation

    private func createLocation(with record: RemoteInventoryLocation, in context: NSManagedObjectContext, configure: LocationItemConfig) throws -> InventoryLocation {
        let location = InventoryLocation(with: record, in: context)

        // Add children
        switch record.locationType {
        case .category:
            location.locationType = "category"
            guard let categories = record.categories else {
                throw InventoriesFactoryError.recordSerializationFailed(reason: "Missing categories")
            }
            for (position, category) in categories.enumerated() {
                let locationCategory = createLocationCategory(record: category, position: position, in: context,
                                                              configure: configure)
                locationCategory.location = location
            }
        case .item:
            location.locationType = "item"
            guard let itemIDs: [Int] = record.items else {
                throw InventoriesFactoryError.recordSerializationFailed(reason: "Missing items")
            }
            for (position, itemID) in itemIDs.enumerated() {
                let locationItem = createLocationItem(itemID: itemID, position: position, in: context,
                                                      configure: configure)
                locationItem.location = location
            }
        }
        return location
    }

    // MARK: InventoryLocationCategory

    private func createLocationCategory(record: RemoteLocationCategory, position: Int, in context: NSManagedObjectContext, configure: LocationItemConfig) -> InventoryLocationCategory {
        let locationCategory = InventoryLocationCategory(context: context)
        locationCategory.categoryID = Int32(record.remoteID)
        locationCategory.name = record.name
        locationCategory.position = Int16(position + 1)

        for (position, itemID) in record.items.enumerated() {
            let locationItem = createLocationItem(itemID: itemID, position: position, in: context, configure: configure)
            locationItem.category = locationCategory
        }
        return locationCategory
    }

    // MARK: InventoryLocationItem

    private func createLocationItem(itemID: Int, position: Int, in context: NSManagedObjectContext, configure: LocationItemConfig) -> InventoryLocationItem {
        let locationItem = InventoryLocationItem(context: context)
        locationItem.itemID = Int32(itemID)
        locationItem.position = Int16(position + 1)
        configure(locationItem, Int32(itemID))
        return locationItem
    }

}
