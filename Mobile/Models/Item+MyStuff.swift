//
//  Item+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/1/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension Item: Syncable {
    typealias RemoteType = RemoteItem
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        self.remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {

        // Required
        //remoteID = record.syncIdentifier
        name = record.name
        //active = remote.active

        // Optional
        packSize = Int16(record.packSize ?? 0)
        //packSize = (record.packSize != nil ?? Int16(record.packSize!) : nil)
        subSize = Int16(record.subSize ?? 0)

        /// NOTE: not implemented:
        // active
        // shelfLife
        // sku
        // vendorItemID

        // Relationships

        // category
        if let remoteCategory = record.category {
            if remoteCategory.syncIdentifier != category?.remoteIdentifier {
                category = ItemCategory.updateOrCreate(with: remoteCategory, in: context)
                // TODO: create new ItemCategory if .fetchWithRemoteIdentifier fails?
                //category = context.fetchWithRemoteIdentifier(ItemCategory.self,
                //                                             identifier: remoteCategory.syncIdentifier)
            }
        } else {
            category = nil
        }

        // store

        // vendor
        if let remoteVendor = record.vendor {
            if remoteVendor.syncIdentifier != vendor?.remoteIdentifier {
                vendor = Vendor.updateOrCreate(with: remoteVendor, in: context)
                // TODO: create new Vendor if .fetchWithRemoteIdentifier fails?
                //vendor = context.fetchWithRemoteIdentifier(Vendor.self, identifier: remoteVendor.syncIdentifier)
            }
        } else {
            vendor = nil
        }

        // units
    }

    func updateUnits(with record: RemoteItem, unitDict: [Int32: Unit]) {
        // TODO: make unitDict optional and fetch if not passed?

        // inventoryUnit
        if let inventoryUnit = record.inventoryUnit {
            self.inventoryUnit = unitDict[Int32(inventoryUnit.remoteID)]
        } else {
            self.inventoryUnit = nil
        }
        // parUnit
        // purchaseUnit
        if let purchaseUnit = record.purchaseUnit {
            self.purchaseUnit = unitDict[Int32(purchaseUnit.remoteID)]
        } else {
            self.purchaseUnit = nil
        }
        // purchaseSubUnit
        if let purchaseSubUnit = record.purchaseSubUnit {
            self.purchaseSubUnit = unitDict[Int32(purchaseSubUnit.remoteID)]
        } else {
            self.purchaseSubUnit = nil
        }
        // subUnit
        if let subUnit = record.subUnit {
            self.subUnit = unitDict[Int32(subUnit.remoteID)]
        } else {
            self.subUnit = nil
        }
    }

    // TODO: should this be marked as `throws`?
    static func sync(with records: [RemoteType], in context: NSManagedObjectContext) {
        // Create dict from fetch request on Items
        let prefetch = ["inventoryUnit", "purchaseSubUnit", "purchaseUnit",
                        "subUnit", "vendor"]
        guard let itemDict = try? Item.fetchEntityDict(in: context, prefetchingRelationships: prefetch) else {
            log.error("\(#function) FAILED : unable to create Item dictionary"); return
        }

        guard let unitDict = try? Unit.fetchEntityDict(in: context) else {
            log.error("\(#function) FAILED : unable to create Unit dictionary"); return
        }

        let localIDs = Set(itemDict.keys)
        var remoteIDs = Set<Int32>()

        for record in records {
            let itemID = Int32(record.remoteID)
            remoteIDs.insert(itemID)

            // Find + update / create Items
            if let existingItem = itemDict[itemID] {
                //log.verbose("UPDATE existing Item: \(existingItem)")
                existingItem.update(with: record, in: context)
                existingItem.updateUnits(with: record, unitDict: unitDict)

            } else {
                //log.verbose("CREATE new Item: \(record)")
                //let newObject = self.init(with: record, in: managedObjectContext)
                let newObject: Item = context.insertObject()
                newObject.remoteID = record.syncIdentifier
                newObject.update(with: record, in: context)
                newObject.updateUnits(with: record, unitDict: unitDict)
            }
        }
        log.debug("Items - remote: \(remoteIDs) - local: \(localIDs)")

        // Delete Items that were deleted from server
        let deletedItems = localIDs.subtracting(remoteIDs)
        if !deletedItems.isEmpty {
            log.debug("We need to delete: \(deletedItems)")
            // TODO: Do we really need to create a new fetch request or can we just get from itemDict?
            let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedItems)
            do {
                try context.deleteEntities(Item.self, filter: fetchPredicate)
            } catch {
                // TODO: deleteEntities(_:filter) already prints the error
                let updateError = error as NSError
                log.error("\(updateError), \(updateError.userInfo)")
            }
        }

        log.verbose("Finished syncing Items")
    }
}

extension Item {

    // TODO: move this to a view model
    var packDisplay: String {
        return "\(self.packSize) x \(self.subSize) \(self.subUnit?.abbreviation ?? " ")"
    }

}

// MARK: - ItemProtocol

extension Item: ItemProtocol {}
