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

    // TODO: shouldn't these methods be named `makeX` according to Raywenderlich styleguide?
    // TODO: shouldn't this be marked as `throws`?
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
        // TODO: can this be cleaned up?
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
        //log.debug("Updating Inventory: \(inventory) with: \(record)")

        // Get / create default location
        //let defaultLocation = InventoryLocation(context: context)
        let locationPredicate = NSPredicate(format: "inventory == %@", inventory)
        let defaultLocation = InventoryLocation.findOrCreate(in: context, matching: locationPredicate) { location in
            location.locationType = InventoryLocationType.item.rawValue
            location.inventory = inventory
            location.name = "Default"
        }

        guard let itemDict = try? Item.fetchEntityDict(in: context) else { return nil }
        guard let unitDict = try? Unit.fetchEntityDict(in: context) else { return nil }
        let locationItemDict = InventoryLocationItem.fetch(in: context) { request in
            request.predicate = NSPredicate(format: "location == %@", defaultLocation)
        }.toDictionary { $0.itemID }

        let predicate = NSPredicate(format: "inventory == %@", inventory)
        // swiftlint:disable:next line_length
        InventoryItem.configurableSync(with: record.items, in: context, matching: predicate) { inventoryItem, remoteRecord in
            //log.debug("Configuring: \(inventoryItem) with: \(remoteRecord)")
            let itemID = remoteRecord.item.syncIdentifier
            let item = itemDict[itemID]

            inventoryItem.inventory = inventory
            inventoryItem.item = item
            inventoryItem.name = item?.name ?? "Error"

            /**
             There will only be one `InventoryLocationItem` for each `InventoryItem` and we won't display them so their
             `.position` doesn't matter

             NOTE: `createLocationItem` also offers a closure `(InventoryLocationItem, Int32) -> Void`
             */
            let locationItem = locationItemDict[itemID] ?? createLocationItem(itemID: remoteRecord.item.remoteID,
                                                                              position: 1, in: context)
            locationItem.location = defaultLocation
            locationItem.item = inventoryItem
            locationItem.quantity = remoteRecord.quantity as NSNumber
            locationItem.unit = unitDict[Int32(remoteRecord.unitId)]

            //log.debug("Configured: \(inventoryItem)\n")
        }
        return inventory
    }

    // MARK: - Private -

    // MARK: Inventory

    private func createInventory(from record: RemoteNewInventory, in context: NSManagedObjectContext) -> Inventory {
        let inventory = Inventory(context: context)
        // remoteID
        if let date = record.date.toBasicDate() {
            inventory.dateTimeInterval = date.timeIntervalSinceReferenceDate
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

    private func createLocationItem(itemID: Int, position: Int, in context: NSManagedObjectContext, configure: LocationItemConfig = { _, _ in }) -> InventoryLocationItem {
        let locationItem = InventoryLocationItem(context: context)
        locationItem.itemID = Int32(itemID)
        locationItem.position = Int16(position + 1)
        configure(locationItem, Int32(itemID))
        return locationItem
    }

}
