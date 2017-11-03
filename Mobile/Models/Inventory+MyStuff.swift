//
//  Inventory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData
//import SwiftyJSON

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
/*
extension Inventory {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, uploaded: Bool = true) {
        self.init(context: context)

        // Set properties
        /// TODO: date and storeID are required and lack default values
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            //self.date = date.timeIntervalSince1970
            self.date = date.timeIntervalSinceReferenceDate
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }

        // Optional / have default value
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let typeID = json["inventory_type_id"].int32 {
            self.typeID = typeID
        }
        self.uploaded = uploaded

        // Add InventoryItems
        if let items = json["items"].array {
            for itemJSON in items {
                _ = InventoryItem(context: context, json: itemJSON, inventory: self)
            }
        }

        // Add InventoryLocations
        if let locations = json["locations"].array {
            for locationJSON in locations {
                _ = InventoryLocation(context: context, json: locationJSON, inventory: self)
            }
        }
    }

    // MARK: - Update Existing

    /// TODO: should this simply be part of .update()?
    func updateExisting(context: NSManagedObjectContext, json: JSON) {

        // Add Default Location
        let defaultLocation = InventoryLocation(context: context, name: "Default", remoteID: 1,
                                                type: InventoryLocationType.category, inventory: self)

        guard let inventoryItems = json["items"].array else {
            log.error("\(#function) FAILED : unable to get InventoryItems from JSON"); return
        }

        // Iterate over Items
        for inventoryItemJSON in inventoryItems {

            // Create InventoryItem
            let inventoryItem = InventoryItem(context: context, json: inventoryItemJSON,
                                              inventory: self)

            // Create InventoryLocationItem
            let locationItem = InventoryLocationItem(context: context)
            if let quantity = inventoryItemJSON["quantity"].double {
                locationItem.quantity = quantity as NSNumber?
            }
            locationItem.item = inventoryItem
            /// TODO: am I still setting location when a LocationItem belongs to a LocationCategory?
            locationItem.location = defaultLocation

            /*
            // Get Corresponding Unit
            if let unitID = inventoryItemJSON["unit_id"].int {
                locationItem.fetchUnit(context: context, id: unitID)
                //if let inventoryUnit = fetchUnit(id: unitID) {
                //    locationItem.unit = inventoryUnit
                //}
            }
            */

            // Fetch / Create corresponding InventoryLocationCategory and create relationships
            defaultLocation.findOrCreateCategory(context: context, json: inventoryItemJSON,
                                                 for: locationItem)

        }
        /// TODO: add position to LocationCategories
        log.verbose("Created InventoryLocation: \(defaultLocation)")
    }

}

extension Inventory: Syncable {

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {
        // guard let json = json as? JSON else {
        //     log.error("\(#function) FAILED : SwiftyJSON"); return
        // }

        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
                //self.date = date.timeIntervalSince1970
                self.date = date.timeIntervalSinceReferenceDate
        }
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        if let typeID = json["inventory_type_id"].int32 {
            self.typeID = typeID
        }
    }

}
*/
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
