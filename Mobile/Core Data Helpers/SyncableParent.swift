//
//  SyncableParent.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import SwiftyJSON

/// TODO: rename to reference relationships
protocol NewSyncableParent: class, NSFetchRequestResult {
    associatedtype ChildType: NewSyncable

    func syncChildren(with: [ChildType.RemoteType], in: NSManagedObjectContext)
    func fetchChildDict(in: NSManagedObjectContext) -> [ChildType.RemoteIdentifierType: ChildType]?
    func updateParent(of: ChildType)
    /// TODO: remove one of these methods; rename to something referencing RemoteDeletion?
    func deleteChildren(localIDs: Set<ChildType.RemoteIdentifierType>, remoteIDs: Set<ChildType.RemoteType.SyncIdentifierType>, in: NSManagedObjectContext)
    func deleteChildren(deletedIDs: Set<ChildType.RemoteType.SyncIdentifierType>, in: NSManagedObjectContext)
}

extension NewSyncableParent where ChildType: NSManagedObject {

    /// TODO: pass closure `configure: (ChildType) -> Void` to allow configuring relationships
    func syncChildren<R, I>(with records: [R], in context: NSManagedObjectContext) where R == ChildType.RemoteType,
        I == ChildType.RemoteIdentifierType, I == ChildType.RemoteType.SyncIdentifierType {
            guard let objectDict: [I: ChildType] = fetchChildDict(in: context) else {
                log.error("\(#function) FAILED : unable to create dictionary for \(ChildType.self)"); return
            }
            log.debug("\(ChildType.self) - objectDict: \(objectDict)")

            let localIDs: Set<I> = Set(objectDict.keys)
            var remoteIDs = Set<I>()

            for record in records {
                let objectID = record.syncIdentifier
                remoteIDs.insert(objectID)

                // Find + update / create Items

                // A
                //let object: ChildType = objectDict[objectID] ?? context.insertObject()
                //object.update(with: record, in: context)
                //updateParent(of: object)

                // B
                if let existingObject = objectDict[objectID] {
                    existingObject.update(with: record, in: context)
                    //log.debug("existingObject: \(existingObject)")
                } else {
                    let newObject = ChildType(context: context)
                    //let newObject: ChildType = context.insertObject()
                    updateParent(of: newObject)
                    newObject.update(with: record, in: context)
                    //log.debug("newObject: \(newObject)")
                }

            }
            log.debug("\(ChildType.self) - remote: \(remoteIDs) - local: \(localIDs)")

            // Delete objects that were deleted from server.

            // A
            //let deletedIDs = localIDs.subtracting(remoteIDs)
            //deleteChildren(deletedIDs: deletedIDs, in: context)

            // B
            deleteChildren(localIDs: localIDs, remoteIDs: remoteIDs, in: context)
    }

    func deleteChildren<I>(localIDs: Set<I>, remoteIDs: Set<I>, in context: NSManagedObjectContext) where I == ChildType.RemoteIdentifierType, I == ChildType.RemoteType.SyncIdentifierType {
        let deletedIDs: Set<I> = localIDs.subtracting(remoteIDs)

        guard !deletedIDs.isEmpty else { return }
        log.debug("We need to delete: \(deletedIDs)")
        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedIDs)
        do {
            try context.deleteEntities(ChildType.self, filter: fetchPredicate)
        } catch let error {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

    func deleteChildren(deletedIDs: Set<ChildType.RemoteIdentifierType>, in context: NSManagedObjectContext) {
        guard !deletedIDs.isEmpty else { return }
        log.debug("We need to delete: \(deletedIDs)")
        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedIDs)
        do {
            try context.deleteEntities(ChildType.self, filter: fetchPredicate)
        } catch let error {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - OLD

/// TODO: rename to reference relationships
protocol SyncableParent: class, NSFetchRequestResult {
    associatedtype ChildType: ManagedSyncable

    func syncChildren(in: NSManagedObjectContext, with: [JSON])
    func fetchChildDict(in: NSManagedObjectContext) -> [Int32: ChildType]?
    func updateParent(of: ChildType)
}

extension SyncableParent where ChildType: NSManagedObject {

    func syncChildren(in context: NSManagedObjectContext, with json: [JSON]) {
        guard let objectDict = fetchChildDict(in: context) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(ChildType.self)"); return
        }
        log.debug("\(ChildType.self) - objectDict: \(objectDict)")

        let localObjects = Set(objectDict.keys)
        var remoteObjects = Set<Int32>()
        for objectJSON in json {
            guard let objectID = objectJSON["id"].int32 else {
                log.warning("\(#function) : unable to get id from \(objectJSON)"); continue
            }
            remoteObjects.insert(objectID)

            // Find + update / create Items
            if let existingObject = objectDict[objectID] {
                existingObject.update(context: context, withJSON: objectJSON)
                //log.debug("existingObject: \(existingObject)")
            } else {
                let newObject = ChildType(context: context)
                updateParent(of: newObject)
                newObject.update(context: context, withJSON: objectJSON)
                //log.debug("newObject: \(newObject)")
            }
        }
        log.debug("\(ChildType.self) - remote: \(remoteObjects) - local: \(localObjects)")

        // Delete objects that were deleted from server.
        let deletedObjects = localObjects.subtracting(remoteObjects)
        deleteChildren(deletedObjects: deletedObjects, context: context)
    }

    private func deleteChildren(deletedObjects: Set<Int32>, context: NSManagedObjectContext) {
        guard !deletedObjects.isEmpty else { return }
        log.debug("We need to delete: \(deletedObjects)")
        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedObjects)
        do {
            try context.deleteEntities(ChildType.self, filter: fetchPredicate)
        } catch let error {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}
