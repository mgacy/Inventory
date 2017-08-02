//
//  NSManagedObjectContext+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

// swiftlint:disable force_cast

// MARK: - Insert
extension NSManagedObjectContext {

    public func insertObject<T: NSManagedObject>(_ entity: T.Type) -> T {
        let newItem = T(context: self)
        return newItem
    }

}

// MARK: - Managed (objc.io)
extension NSManagedObjectContext {

    func insertObject<T: NSManagedObject>() -> T where T: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T else {
            fatalError("Wrong object type")
        }
        return obj
    }

}

// MARK: - Fetch
extension NSManagedObjectContext {

    /// NOTE: this is a more general form of fetchWithRemoteID(_:withID)
    public func fetchSingleEntity<T: NSManagedObject>(_ entity: T.Type, matchingPredicate predicate: NSPredicate) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                log.debug("Found 0 matches for predicate \(predicate)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED : found multiple matches: \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("Error with request: \(error)")
            //throw error?
        }
        return nil
    }

    // http://codereview.stackexchange.com/questions/147005/swift-3-generic-fetch-request-extension
    func fetchEntities<T: NSManagedObject>(_ entityClass: T.Type, sortBy: [NSSortDescriptor]? = nil, matchingPredicate predicate: NSPredicate? = nil) throws -> [T] {

        let request: NSFetchRequest<T>
        if #available(iOS 10.0, *) {
            request = entityClass.fetchRequest() as! NSFetchRequest<T>
        } else {
            let entityName = String(describing: entityClass)
            request = NSFetchRequest(entityName: entityName)
        }

        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortBy

        do {
            let fetchedResult = try self.fetch(request)
            return fetchedResult
        } catch let error {
            /// TODO: provide better error info?
            log.error(error.localizedDescription)
            throw error
        }
    }

}

// MARK: - Delete
extension NSManagedObjectContext {

    func deleteEntities<T: NSManagedObject>(_ entityClass: T.Type, filter: NSPredicate? = nil) throws {

        /// TODO: actually throw on exception?

        // Ensure any changes are first pushed to the persistent store
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                let saveError = error as NSError
                log.error("\(saveError), \(saveError.userInfo)")
                //throw saveError?
            }
        }

        // Initialize, configure fetch request
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        if let filter = filter { fetchRequest.predicate = filter }

        // Initialize, configure batch delete request
        let batchDeleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeCount

        do {
            let batchDeleteResult = try self.execute(batchDeleteRequest) as! NSBatchDeleteResult
            log.verbose("The batch delete request has deleted \(batchDeleteResult.result!) records.")

            // As the request directly interacts with the persistent store, we need need to reset the context for it to be aware of the changes
            self.reset()
        } catch {
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
            //throw updateError?
        }
    }

}

// MARK: - Save
// objc.io - Core Data
extension NSManagedObjectContext {

    public func saveOrRollback() -> Bool {
        /// TODO: proceed only if self.hasChanges?
        do {
            try save()
            return true
        } catch {
            let nserror = error as NSError
            log.error("Unresolved error while saving: \(nserror), \(nserror.userInfo)")

            rollback()
            return false
        }
    }

    public func performSaveOrRollback() {
        perform {
            _ = self.saveOrRollback()
        }
    }

    public func performChanges(block: @escaping () -> Void) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }

}

// MARK: - Syncable -

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

// MARK: - SyncableCollection -

extension NSManagedObjectContext {

    func fetchByDate<T: SyncableCollection>(_ entity: T.Type, withDate date: String) -> T? where T: NSManagedObject {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "date == %@", date)
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                log.debug("\(#function) : found 0 matches for date: \(date)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED : found multiple matches: \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("\(#function) FAILED : error with request: \(error)")
            //throw error?
        }
        return nil
    }

    func fetchCollectionDict<T: SyncableCollection>(_ entityClass: T.Type, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [String: T] where T: NSManagedObject {

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
            let objectDict = fetchedResult.toDictionary { $0.date! }
            return objectDict
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }

    /// TODO: add `uploaded: Bool = true`?

    public func syncCollections<T: SyncableCollection>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        // Filter new (uploaded = false) collections
        let fetchPredicate = NSPredicate(format: "uploaded == %@", NSNumber(value: true))
        guard let objectDict = try? fetchCollectionDict(T.self, matching: fetchPredicate) else {
            log.error("\(#function) FAILED : unable to create Collection dictionary"); return
        }

        let localDates = Set(objectDict.keys)
        var remoteDates = Set<String>()

        for (_, objectJSON):(String, JSON) in json {
            guard let objectDate = objectJSON["date"].string else {
                log.warning("\(#function) : unable to get date from \(objectJSON)")
                continue
            }
            remoteDates.insert(objectDate)

            // Find + update / create Items
            if let existingObject = objectDict[objectDate] {
                existingObject.update(context: self, withJSON: objectJSON)
            } else {
                //_ = T(context: self, json: objectJSON)
                let newObject = T(context: self)
                newObject.update(context: self, withJSON: objectJSON, uploaded: true)
            }
        }
        log.debug("\(T.self) - remote: \(remoteDates) - local: \(localDates)")

        // Delete objects that were deleted from server.
        let deletedObjects = localDates.subtracting(remoteDates)
        if !deletedObjects.isEmpty {
            log.debug("We need to delete: \(deletedObjects)")
            let fetchPredicate = NSPredicate(format: "date IN %@", deletedObjects)
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
