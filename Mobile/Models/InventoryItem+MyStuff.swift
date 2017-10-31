//
//  InventoryItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData
import SwiftyJSON

extension InventoryItem: NewSyncable {
    typealias RemoteType = RemoteInventoryItem
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        self.remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // categoryID:  ?
        // itemID:      ?
        // name:        ?
        // remoteID:    ?

        // Relationships
        // inventory:   Inventory
        // item:        Item
        // items:       InventoryLocationItem

        self.itemID = record.item.syncIdentifier
    }

}

// MARK: - Configurable Sync

extension InventoryItem {

    static func configurableSync(with records: [RemoteType], in context: NSManagedObjectContext, matching predicate: NSPredicate? = nil, configure: (InventoryItem, RemoteType) -> Void = { _, _ in }) {

        guard let objectDict: [Int32: InventoryItem] = try? fetchEntityDict(in: context, matching: predicate) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(self)"); return
        }

        let localIDs: Set<Int32> = Set(objectDict.keys)
        var remoteIDs = Set<Int32>()

        for record in records {
            let objectID = record.syncIdentifier
            remoteIDs.insert(objectID)

            // Find + update / create Items
            if let existingObject = objectDict[objectID] {
                existingObject.update(with: record, in: context)
                configure(existingObject, record)
                //log.debug("existingObject: \(existingObject)")
            } else {
                let newObject = InventoryItem(with: record, in: context)
                configure(newObject, record)
                /// TODO: add newObject to localIDs?
                log.debug("newObject: \(newObject)")
            }

        }

        log.debug("\(self) - remote: \(remoteIDs) - local: \(localIDs)")
        let deletedIDs = localIDs.subtracting(remoteIDs)
        deleteItems(withIDs: deletedIDs, in: context)
    }

    static func deleteItems(withIDs deletionIDs: Set<Int32>, in context: NSManagedObjectContext) {
        guard !deletionIDs.isEmpty else { return }
        log.debug("We need to delete: \(deletionIDs)")
        /// TODO: remove hard-coded predicate string
        let fetchPredicate = NSPredicate(format: "\(self.remoteIdentifierName) IN %@", deletionIDs)
        do {
            try context.deleteEntities(self, filter: fetchPredicate)
        } catch let error {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - OLD

extension InventoryItem {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON,
                     inventory: Inventory) {
        self.init(context: context)

        // Is this the best way to determine whether response is for a new or
        // an existing InventoryItem?
        if json["item"]["id"].int != nil {
            initExisting(context: context, json: json)
        } else {
            initNew(context: context, json: json)
        }

        // Relationship
        self.inventory = inventory
    }

    private func initNew(context: NSManagedObjectContext, json: JSON) {

        if let itemID = json["id"].int32 {
            self.itemID = itemID
            //if let item = context.fetchWithRemoteID(Item.self, withID: itemID) {
            if let item = context.fetchWithRemoteIdentifier(Item.self, identifier: itemID) {
                self.item = item
            } else {
                log.warning("\(#function) : unable to fetch Item with remoteID \(itemID) for \(self)")
            }
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let categoryID = json["category_id"].int32 {
            self.categoryID = categoryID
        }
    }

    private func initExisting(context: NSManagedObjectContext, json: JSON) {

        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["item"]["name"].string {
            self.name = name
        }
        if let itemID = json["item"]["id"].int32 {
            self.itemID = itemID
            //self.item = context.fetchWithRemoteID(Item.self, withID: itemID)
            self.item = context.fetchWithRemoteIdentifier(Item.self, identifier: itemID)
        }
        if let categoryID = json["item"]["category"]["id"].int32 {
            self.categoryID = categoryID
        }

        //if let quantity = json["quantity"].double {
        //    self.quantity = Int32(quantity)
        //}
        // if let unitID = json["unit_id"].int {
    }

}

// MARK: - Serialization

extension InventoryItem {

    public func serialize() -> [String: Any] {
        var itemDict: [String: Any] = [
            "item_id": Int(self.itemID),
            "quantity": 0.0
        ]

        guard let items = self.items else {
            return itemDict
        }

        var subTotal = 0.0
        for case let item as InventoryLocationItem in items where item.quantity != nil {
            subTotal += Double(truncating: item.quantity!)
        }
        itemDict["quantity"] = subTotal

        return itemDict
    }

}
