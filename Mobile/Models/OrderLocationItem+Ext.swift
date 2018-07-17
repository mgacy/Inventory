//
//  OrderLocationItem+Ext.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/23/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import CoreData

extension OrderLocationItem: Managed {
    typealias RemoteType = RemoteNestedItem
    typealias RemoteIdentifierType = Int32

    //var remoteIdentifier: Int32 { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        // remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        itemID = record.syncIdentifier
        // position

        /// Relationships
        // category?
        // location?
        // item
    }

}

// MARK: - Location Sync

extension OrderLocationItem {
    typealias SyncConfig = (OrderLocationItem, RemoteType) -> Void

    convenience init(with record: RemoteType, in context: NSManagedObjectContext, configure: SyncConfig) {
        self.init(context: context)
        // remoteID = record.syncIdentifier
        update(with: record, in: context, configure: configure)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext, configure: SyncConfig) {
        itemID = record.syncIdentifier
        // position

        /// Relationships
        // category?
        // location?
        // item
        configure(self, record)
    }

    static func fetchEntityDict<T: Hashable>(in context: NSManagedObjectContext,
                                             matching predicate: NSPredicate?,
                                             prefetchingRelationships relationships: [String]? = nil,
                                             returningAsFaults asFaults: Bool = false,
                                             withKey selectKey: (OrderLocationItem) -> T)
        -> [T: OrderLocationItem]? {
            let request: NSFetchRequest<OrderLocationItem> = OrderLocationItem.fetchRequest()

            /*
             Set returnsObjectsAsFaults to false to gain a performance benefit if you know
             you will need to access the property values from the returned objects.
             */
            request.returnsObjectsAsFaults = asFaults
            request.predicate = predicate
            request.relationshipKeyPathsForPrefetching = relationships

            do {
                let fetchResults = try context.fetch(request)
                return fetchResults.toDictionary(with: selectKey)
            } catch let error {
                log.error("\(#function) FAILED : \(error)")
                //throw error
                return nil
            }
    }

}
