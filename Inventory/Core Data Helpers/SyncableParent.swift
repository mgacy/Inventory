//
//  SyncableParent.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData

// TODO: rename to reference relationships
protocol SyncableParent: class, NSFetchRequestResult {
    associatedtype ChildType: Syncable

    func syncChildren(with: [ChildType.RemoteType], in: NSManagedObjectContext)
    func fetchChildDict(in: NSManagedObjectContext) -> [ChildType.RemoteIdentifierType: ChildType]?
    func updateParent(of: ChildType)
    // TODO: rename to something referencing RemoteDeletion?
    func deleteChildren(withIdentifiers: Set<ChildType.RemoteType.SyncIdentifierType>, in: NSManagedObjectContext)
}

extension SyncableParent where ChildType: NSManagedObject {

    // TODO: pass closure `configure: (ChildType) -> Void` to allow configuring relationships
    func syncChildren<R, I>(with records: [R], in context: NSManagedObjectContext) where R == ChildType.RemoteType,
        I == ChildType.RemoteIdentifierType, I == ChildType.RemoteType.SyncIdentifierType {
            guard let objectDict: [I: ChildType] = fetchChildDict(in: context) else {
                log.error("\(#function) FAILED : unable to create dictionary for \(ChildType.self)"); return
            }
            log.verbose("\(ChildType.self) - objectDict: \(objectDict)")

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
                    log.verbose("existingObject: \(existingObject)")
                } else {
                    let newObject = ChildType(with: record, in: context)
                    //let newObject = ChildType(context: context)
                    //let newObject: ChildType = context.insertObject()
                    //newObject.update(with: record, in: context)
                    updateParent(of: newObject)
                    log.verbose("newObject: \(newObject)")
                }

            }
            log.verbose("\(ChildType.self) - remote: \(remoteIDs) - local: \(localIDs)")

            // Delete objects that were deleted from server.
            let deletedIDs = localIDs.subtracting(remoteIDs)
            deleteChildren(withIdentifiers: deletedIDs, in: context)
    }

    func deleteChildren(withIdentifiers identifiers: Set<ChildType.RemoteIdentifierType>, in context: NSManagedObjectContext) {
        guard !identifiers.isEmpty else { return }
        log.verbose("We need to delete: \(identifiers)")
        let fetchPredicate = NSPredicate(format: "\(ChildType.remoteIdentifierName) IN %@", identifiers)
        do {
            try context.deleteEntities(ChildType.self, filter: fetchPredicate)
        } catch let error {
            // TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}
