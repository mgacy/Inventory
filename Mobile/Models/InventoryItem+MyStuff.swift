//
//  InventoryItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension InventoryItem: Syncable {
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
