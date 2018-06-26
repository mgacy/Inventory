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
        /// FIXME: InventoryLocationCategory does have .id, but response from /inventory_locations returns id of ItemCategory
        // remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // remoteID
        name = record.name
        categoryID = record.syncIdentifier

        /// Relationships
        // location
        // items?
    }

}

