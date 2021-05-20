//
//  OrderLocationCategory+Ext.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/23/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import CoreData

extension OrderLocationCategory: Managed {
    typealias RemoteType = RemoteItemCategory
    //typealias RemoteIdentifierType = Int32

    //var remoteIdentifier: Int32 { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        // FIXME: InventoryLocationCategory does have .id, but response from /inventory_locations returns id of ItemCategory
        // remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // remoteID
        name = record.name
        categoryID = record.syncIdentifier

        // Relationships
        // location
        // items?
    }

}

// MARK: - Location Sync

extension OrderLocationCategory {
    typealias ChildConfig = (OrderLocationItem, OrderLocationItem.RemoteType) -> Void

    convenience init(with record: RemoteType, in context: NSManagedObjectContext, configure: ChildConfig = { _, _ in }) {
        self.init(context: context)
        //remoteID = record.syncIdentifier
        update(with: record, in: context, configureChildren: configure)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext, configureChildren: ChildConfig = { _, _ in }) {
        // remoteID
        name = record.name
        // categoryID
        // position

        // Relationships
        // location
        guard let itemRecords = record.items else {
            return
        }
        let localCount = items?.count ?? 0
        let remoteCount = itemRecords.count
        log.verbose("Counts - local: \(localCount) - remote: \(remoteCount)")

        for (position, locationItem) in itemRecords.enumerated() {
            if position < localCount {
                if let existingObject = items?.object(at: position) as? OrderLocationItem {
                    existingObject.update(with: locationItem, in: context, configure: configureChildren)
                    log.verbose("Updated Item: \(existingObject)")
                } else {
                    log.error("\(#function) FAILED : \(locationItem)")
                }
            } else {
                let newObject = OrderLocationItem(with: locationItem, in: context, configure: configureChildren)
                newObject.position = Int16(position)
                newObject.category = self
                log.verbose("Created Item: \(newObject)")
            }
        }

        /// Delete any local objects not in remote records
        if localCount > remoteCount {
            for position in (remoteCount ..< localCount).reversed() {
                if let object = items?.object(at: position) as? OrderLocationItem {
                    context.delete(object)
                } else {
                    log.error("\(#function) FAILED : unable to delete OrderLocationItem at position: \(position)")
                }
            }
        }
    }

}
