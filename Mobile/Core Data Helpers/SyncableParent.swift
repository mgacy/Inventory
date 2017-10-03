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
