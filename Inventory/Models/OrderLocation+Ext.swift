//
//  OrderLocation+Ext.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/23/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import CoreData

// MARK: - Syncable

extension OrderLocation: Syncable {
    typealias RemoteType = RemoteLocation
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: Int32 { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // remoteID
        // locationID - Not included in response from /inventory_locations
        name = record.name
        locationType = record.locationType.converted().rawValue

        /// Relationships
        // collection
        // categories?
        // items?
        /*
        switch record.locationType {
        case .category:
            print("Type: category")
            for locationCategory in record.categories {
                // ...
            }
        case .item:
            print("Type: item")
            for locationItem in record.items {
                // ...
            }
        }
        */
    }

}

// MARK: - Location Sync

extension OrderLocation {
    typealias SyncConfig = (OrderLocation, RemoteType) -> Void
    typealias ChildConfig = (OrderLocationItem, OrderLocationItem.RemoteType) -> Void
    //typealias CompoundConfig = (SyncConfig, ChildConfig) (-> Void)?

    convenience init(with record: RemoteType, in context: NSManagedObjectContext, configureChildren: ChildConfig) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context, configureChildren: configureChildren)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext, configureChildren: ChildConfig) {
        // remoteID
        // locationID - Not included in response from /inventory_locations
        name = record.name
        locationType = record.locationType.converted().rawValue

        // Relationships
        // collection
        // categories?
        // items?
        let fetchPredicate = NSPredicate(format: "location == %@", self)
        switch record.locationType {
        case .category:
            let localCount = categories?.count ?? 0
            let remoteCount = record.categories.count
            //log.verbose("Counts - local: \(localCount) - remote: \(remoteCount)")

            for (position, locationCategory) in record.categories.enumerated() {
                if position < localCount {
                    if let existingObject = categories?.object(at: position) as? OrderLocationCategory {
                        existingObject.update(with: locationCategory, in: context, configureChildren: configureChildren)
                        //log.verbose("Updated Category: \(existingObject)")
                    } else {
                        log.error("\(#function) FAILED : \(locationCategory)")
                    }
                } else {
                    let newObject = OrderLocationCategory(with: locationCategory, in: context,
                                                          configure: configureChildren)
                    newObject.position = Int16(position)
                    newObject.location = self
                    //log.verbose("Created Category: \(newObject)")
                }
            }

            // Delete any local objects not in remote records
            if localCount > remoteCount {
                for position in (remoteCount ..< localCount).reversed() {
                    if let object = categories?.object(at: position) as? OrderLocationCategory {
                        context.delete(object)
                    } else {
                        log.error("\(#function) FAILED : unable to delete OrderLocationCategory at position: \(position)")
                    }
                }
            }
        case .item:
            // swiftlint:disable:next line_length
            let locItemDict = OrderLocationItem.fetchEntityDict(in: context, matching: fetchPredicate) { Int($0.position) } ?? [Int: OrderLocationItem]()

            for (position, record) in record.items.enumerated() {
                if let existingObject = locItemDict[position] {
                    existingObject.update(with: record, in: context, configure: configureChildren)
                } else {
                    let newObject = OrderLocationItem(with: record, in: context, configure: configureChildren)
                    newObject.position = Int16(position)
                    newObject.location = self
                }
            }

            // Handle deleted objects
            //let objectsToDelete = Set(locItemDict.keys).subtracting(record.items.map { $0.position })
            if locItemDict.keys.count > record.items.count {
                for position in (record.items.count ..< locItemDict.keys.count).reversed() {
                    //guard let itemForDeletion = locItemDict[position] else { break }
                    //context.delete(itemForDeletion)
                    if let itemForDeletion = locItemDict[position] {
                        context.delete(itemForDeletion)
                    } else {
                        log.error("\(#function) FAILED : unable to delete OrderLocationItem at position: \(position)")
                    }
                }
            }
        }
    }

    // TODO: rename `configure` as `configureRelationship`?
    // TODO: should this throw?
    static func syncLocations(belongingTo parent: OrderCollection,
                              with records: [RemoteType],
                              in context: NSManagedObjectContext)
        -> [OrderLocation] {
            let predicate = NSPredicate(format: "collection == %@", parent)
            guard let locationDict: [RemoteIdentifierType: OrderLocation] = try? fetchEntityDict(
                in: context, matching: predicate, prefetchingRelationships: ["categories", "items"]) else {
                    log.error("\(#function) FAILED : unable to create dictionary for \(self)"); return []
            }
            let orderItemDict = OrderItem.fetchOrderItemDict(for: parent, in: context) ?? [Int32: OrderItem]()

            let localIDs: Set<RemoteIdentifierType> = Set(locationDict.keys)
            var remoteIDs = Set<RemoteIdentifierType>()
            var returnValue = [OrderLocation]()
            for record in records {
                let objectID = record.syncIdentifier
                remoteIDs.insert(objectID)

                // Find + update / create Items
                if let existingObject = locationDict[objectID] {
                    existingObject.update(with: record, in: context) { locationItem, locationItemRecord in
                        guard let orderItem = orderItemDict[locationItemRecord.syncIdentifier] else {
                            context.delete(locationItem); return
                        }
                        locationItem.item = orderItem
                        log.verbose("Item: \(locationItem)")
                    }
                    returnValue.append(existingObject)
                    log.verbose("Updated Location: \(existingObject)")
                } else {
                    let newObject = OrderLocation(with: record, in: context) { locationItem, locationItemRecord in
                        guard let orderItem = orderItemDict[locationItemRecord.syncIdentifier] else {
                            context.delete(locationItem); return
                        }
                        locationItem.item = orderItem
                        log.verbose("Item: \(locationItem)")
                    }
                    newObject.collection = parent
                    returnValue.append(newObject)
                    log.verbose("Created Location: \(newObject)")
                }
            }

            log.verbose("\(self) - remote: \(remoteIDs) - local: \(localIDs)")

            // Delete objects that were deleted from server. We filter remoteID 0 (the default value for new objects)
            let deletedObjects: Set<RemoteIdentifierType> = localIDs.subtracting(remoteIDs).filter { $0 != 0 }
            delete(withIdentifiers: deletedObjects, in: context, matching: predicate)

            //let saveResult = context.saveOrRollback()
            //log.verbose("Saved: \(saveResult)")

            return returnValue
    }

    static func delete(withIdentifiers identifiers: Set<RemoteIdentifierType>, in context: NSManagedObjectContext, matching predicate: NSPredicate? = nil) {
        log.verbose("We need to delete: \(identifiers)")
        guard !identifiers.isEmpty else { return }

        let fetchPredicate: NSPredicate
        if let additionalPredicate = predicate {
            fetchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(remoteIdentifierName) IN %@", identifiers), additionalPredicate])
        } else {
            fetchPredicate = NSPredicate(format: "\(remoteIdentifierName) IN %@", identifiers)
        }

        do {
            try context.deleteEntities(self, filter: fetchPredicate)
        } catch {
            // TODO: deleteEntities(_:filter) already logs the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
            //throw updateError?
        }
    }

}
