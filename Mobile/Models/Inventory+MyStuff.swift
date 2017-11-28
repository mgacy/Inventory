//
//  Inventory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension Inventory: NewSyncable {
    typealias RemoteType = RemoteInventory
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        self.uploaded = true
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID
        if let date = record.date.toBasicDate() {
            self.date = date.timeIntervalSinceReferenceDate
        }
        storeID = Int32(record.storeID)
        typeID = Int32(record.inventoryTypeID ?? 0)
        //uploaded

        //items: [InventoryItem]
        //locations: [InventoryLocation]
    }

}

//extension Inventory: DateFacade {}

// MARK: - Serialization

extension Inventory {

    func serialize() -> [String: Any]? {
        guard let items = self.items else {
            log.error("\(#function) FAILED : unable to serialize without any InventoryItems")
            return nil
        }

        var myDict = [String: Any]()
        myDict["date"] = date.toPythonDateString()
        myDict["store_id"] = storeID

        // Apple suggests using a default value of 0 over using optional attributes
        if typeID != 0 {
            myDict["inventory_type_id"] = typeID
        }

        // Generate array of dictionaries for InventoryItems
        var itemsArray = [[String: Any]]()
        for case let item as InventoryItem in items {
            itemsArray.append(item.serialize())
        }
        myDict["items"] = itemsArray

        return myDict
    }

}
