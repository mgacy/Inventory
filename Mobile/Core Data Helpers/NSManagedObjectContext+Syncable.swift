//
//  NSManagedObjectContext+Syncable.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import SwiftyJSON

// swiftlint:disable force_cast

// MARK: - NEW

extension NSManagedObjectContext {

    func fetchWithRemoteIdentifier<T: NewSyncable, I>(_ entity: T.Type, identifier id: I) -> T? where T: NSManagedObject, I == T.RemoteIdentifierType {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "\(entity.remoteIdentifierName) == \(id)")
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                log.debug("\(#function) : found 0 matches for remoteIdentifier \(id)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED: found multiple matches for remoteIdentifier \(id): \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("\(#function) FAILED : error with request: \(error)")
            return nil
            //throw error?
        }
    }

    func fetchEntityDict<T: NewSyncable, I>(_ entityClass: T.Type, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [I: T] where T: NSManagedObject, I == T.RemoteIdentifierType {

        //let request: NSFetchRequest<T> = entityClass.fetchRequest() as! NSFetchRequest<T>
        let request = NSFetchRequest<T>(entityName: T.entityName)

        /*
         Set returnsObjectsAsFaults to false to gain a performance benefit if you know
         you will need to access the property values from the returned objects.
         */
        request.returnsObjectsAsFaults = asFaults
        request.predicate = predicate
        request.relationshipKeyPathsForPrefetching = relationships

        do {
            let fetchedResult = try self.fetch(request)
            return fetchedResult.toDictionary { $0.remoteIdentifier }
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }
    /*
    func syncEntities<T: NewSyncable, R, I>(_ entity: T.Type, with records: [R]) throws where T: NSManagedObject, R == T.RemoteType, I == T.RemoteIdentifierType, I == R.SyncIdentifierType {
        guard let objectDict = try? fetchEntityDict(T.self) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(T.self)"); return
        }

        let localIDs: Set<I> = Set(objectDict.keys)
        var remoteIDs = Set<I>()

        for record in records {
            let objectID = record.syncIdentifier
            remoteIDs.insert(objectID)

            // Find + update / create Items
            let object = objectDict[objectID] ?? T(context: self)
            object.update(with: record, in: self)
        }

        log.debug("\(T.self) - remote: \(remoteIDs) - local: \(localIDs)")

        /// TODO: switch to using overridable deleteChildren method as in SyncableParent?
        // Delete objects that were deleted from server. We filter remoteID 0
        // since that is the default value for new objects
        let deletedObjects: Set<I>
        switch I.self {
        case is Int32.Type:
            deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 as? Int32 != 0 }
        case is Int.Type:
            deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 as? Int != 0 }
        default:
            deletedObjects = localIDs.subtracting(remoteIDs)
        }

        if !deletedObjects.isEmpty {
            log.debug("We need to delete: \(deletedObjects)")
            let fetchPredicate = NSPredicate(format: "\(entity.remoteIdentifierName) IN %@", deletedObjects)
            do {
                try self.deleteEntities(T.self, filter: fetchPredicate)
            } catch {
                /// TODO: deleteEntities(_:filter) already prints the error
                let updateError = error as NSError
                log.error("\(updateError), \(updateError.userInfo)")
                //throw updateError?
            }
        }
    }
     */
}

// MARK: - / NEW

extension NSManagedObjectContext {

    // MARK: Insert

    public func insertObjectWithJSON<T: Syncable>(_ entity: T.Type, withJSON json: JSON) -> T where T: NSManagedObject {
        let newItem = T(context: self)
        newItem.update(context: self, withJSON: json)
        return newItem
    }

    // MARK: Fetch

    public func fetchWithRemoteID<T: Syncable>(_ entity: T.Type, withID id: Int32) -> T? where T: NSManagedObject {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "remoteID == \(id)")
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                log.debug("\(#function) : found 0 matches for remoteID \(id)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED: found multiple matches for remoteID \(id): \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("\(#function) FAILED : error with request: \(error)")
            return nil
            //throw error?
        }
    }

    func fetchEntityDict<T: Syncable>(_ entityClass: T.Type, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [Int32: T] where T: NSManagedObject {

        let request: NSFetchRequest<T>
        if #available(iOS 10.0, *) {
            request = entityClass.fetchRequest() as! NSFetchRequest<T>
        } else {
            let entityName = String(describing: entityClass)
            request = NSFetchRequest(entityName: entityName)
        }

        /*
         Set returnsObjectsAsFaults to false to gain a performance benefit if you know
         you will need to access the property values from the returned objects.
         */
        request.returnsObjectsAsFaults = asFaults
        request.predicate = predicate
        request.relationshipKeyPathsForPrefetching = relationships

        do {
            let fetchedResult = try self.fetch(request)
            let objectDict = fetchedResult.toDictionary { $0.remoteID }
            return objectDict
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }

    // MARK: Sync

    /// TODO: add filter predicate arg with default value of nil to pass to fetchEntityDict?
    public func syncEntities<T: Syncable>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        guard let objectDict = try? fetchEntityDict(T.self) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(T.self)"); return
        }

        let localIDs = Set(objectDict.keys)
        var remoteIDs = Set<Int32>()

        for (_, objectJSON):(String, JSON) in json {
            guard let objectID = objectJSON["id"].int32 else {
                log.warning("\(#function) : unable to get id from \(objectJSON)")
                continue
            }
            remoteIDs.insert(objectID)

            // Find + update / create Items
            if let existingObject = objectDict[objectID] {
                existingObject.update(context: self, withJSON: objectJSON)
            } else {
                //_ = T(context: self, json: objectJSON)
                let newObject = T(context: self)
                newObject.update(context: self, withJSON: objectJSON)
            }
        }
        log.debug("\(T.self) - remote: \(remoteIDs) - local: \(localIDs)")

        // Delete objects that were deleted from server. We filter remoteID 0
        // since that is the default value for new objects
        let deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 != 0 }
        if !deletedObjects.isEmpty {
            log.debug("We need to delete: \(deletedObjects)")
            let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedObjects)
            do {
                try self.deleteEntities(T.self, filter: fetchPredicate)
            } catch {
                /// TODO: deleteEntities(_:filter) already prints the error
                let updateError = error as NSError
                log.error("\(updateError), \(updateError.userInfo)")
                //throw updateError?
            }
        }
    }

}
