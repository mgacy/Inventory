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

// MARK: - Insert
extension NSManagedObjectContext {

    public func insertObject<T : NSManagedObject>(_ entity: T.Type) -> T {
        let newItem = T(context: self)
        return newItem
    }

}

// MARK: - Fetch
extension NSManagedObjectContext {

    // NOTE - this is a more general form of fetchWithRemoteID(_:withID)
    public func fetchSingleEntity<T : NSManagedObject>(_ entity: T.Type, matchingPredicate predicate: NSPredicate) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                //log.warning("Found 0 matches for predicate \(predicate)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED : found multiple matches: \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("Error with request: \(error)")
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

        //let fetchedResult = try self.fetch(request)
        //return fetchedResult
        do {
            let fetchedResult = try self.fetch(request)
            return fetchedResult
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }

}

// MARK: - Delete
extension NSManagedObjectContext {

    func deleteEntities<T: NSManagedObject>(_ entityClass: T.Type, filter: NSPredicate? = nil) throws {

        // We need to make sure that any changes are first pushed to the persistent store
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                let saveError = error as NSError
                log.error("\(saveError), \(saveError.userInfo)")
            }
        }

        // Create Fetch Request
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>

        // Configure Fetch Request
        if let filter = filter { fetchRequest.predicate = filter }

        // Initialize Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult = try self.execute(batchDeleteRequest) as! NSBatchDeleteResult

            log.verbose("The batch delete request has deleted \(batchDeleteResult.result!) records.")

            // Reset Managed Object Context
            // As the request directly interacts with the persistent store, we need need to reset the context
            // for it to be aware of the changes
            self.reset()

        } catch {
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

    /*
    // http://collindonnell.com/2015/07/22/swift-delete-all-objects-extension/
    func deleteEverything() {
        // if let entitesByName = persistentStoreCoordinator?.managedObjectModel.entitiesByName as? [String: NSEntityDescription] {
        if let entitesByName = persistentStoreCoordinator?.managedObjectModel.entitiesByName {
            for (name, entityDescription) in entitesByName {
                do {
                    //try deleteEntities(entityDescription.self)
                    //try deleteEntities(name)

                } catch {
                    log.error("\(#function) FAILED: stuff")
                }

            }
        }
    }
    */

}

// MARK: - Syncable
extension NSManagedObjectContext {

    // MARK: Insert

    public func insertObjectWithJSON<T : Syncable>(_ entity: T.Type, withJSON json: JSON) -> T where T: NSManagedObject {
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
                //log.warning("Found 0 matches for remoteID \(id)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            log.error("Error with request: \(error)")
            return nil
        }
        //return nil
    }

    func fetchEntityDict<T: Syncable>(_ entityClass: T.Type,
                         matchingPredicate predicate: NSPredicate? = nil,
                         prefetchingRelationships relationships: [String]? = nil,
                         returningAsFaults asFaults: Bool = false
        ) throws -> [Int32: T] where T: NSManagedObject {

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

        //let fetchedResult = try self.fetch(request)
        //return fetchedResult
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

    public func syncEntities<T : Syncable>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        guard let objectDict = try? fetchEntityDict(T.self) else {
            log.error("\(#function) FAILED : unable to create Item dictionary"); return
        }

        let localIDs = Set(objectDict.keys)
        var remoteIDs = Set<Int32>()

        for (_, objectJSON):(String, JSON) in json {
            guard let objectID = objectJSON["id"].int32 else { continue }
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

        // Delete objects that were deleted from server. We filter remoteID 0
        // since that is the default value for new objects
        let deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 != 0 }

        // TESTING
        //log.debug("remote: \(remoteIDs) - local: \(localIDs)")
        //log.debug("We need to delete: \(deletedObjects)")

        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedObjects)
        do {
            try self.deleteEntities(T.self, filter: fetchPredicate)
        } catch {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

    // NOTE - if we don't provide another method for SyncableItems, Syncable.update
    // will override the update method of any(?) SyncableItems
    public func syncEntities<T : SyncableItem>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        guard let objectDict = try? fetchEntityDict(T.self) else {
            log.error("\(#function) FAILED : unable to create Item dictionary"); return
        }

        let localIDs = Set(objectDict.keys)
        var remoteIDs = Set<Int32>()

        for (_, objectJSON):(String, JSON) in json {
            guard let objectID = objectJSON["id"].int32 else { continue }
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

        // Delete objects that were deleted from server. We filter remoteID 0
        // since that is the default value for new objects
        let deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 != 0 }

        // TESTING
        log.debug("remote: \(remoteIDs) - local: \(localIDs)")
        log.debug("We need to delete: \(deletedObjects)")

        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedObjects)
        do {
            try self.deleteEntities(T.self, filter: fetchPredicate)
        } catch {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: SyncableCollection
extension NSManagedObjectContext {

    func fetchByDate<T: SyncableCollection>(_ entity: T.Type, withDate date: String) -> T? where T: NSManagedObject {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "date == %@", date)
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                //log.warning("Found 0 matches for predicate \(predicate)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                log.error("\(#function) FAILED: found multiple matches: \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
                //print("Found multiple matches: \(searchResults)")
                //return searchResults[0]
            }

        } catch let error {
            log.error("Error with request: \(error)")
        }
        return nil
    }

    func fetchCollectionDict<T: SyncableCollection>(_ entityClass: T.Type,
                             matchingPredicate predicate: NSPredicate? = nil,
                             prefetchingRelationships relationships: [String]? = nil,
                             returningAsFaults asFaults: Bool = false
        ) throws -> [String: T] where T: NSManagedObject {

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

        //let fetchedResult = try self.fetch(request)
        //return fetchedResult
        do {
            let fetchedResult = try self.fetch(request)
            let objectDict = fetchedResult.toDictionary { $0.date! }
            return objectDict
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }

    public func syncCollections<T: SyncableCollection>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        guard let objectDict = try? fetchCollectionDict(T.self) else {
            log.error("\(#function) FAILED : unable to create Collection dictionary"); return
        }

        let localDates = Set(objectDict.keys)
        var remoteDates = Set<String>()

        for (_, objectJSON):(String, JSON) in json {
            guard let objectDate = objectJSON["date"].string else { continue }
            remoteDates.insert(objectDate)

            // Find + update / create Items
            if let existingObject = objectDict[objectDate] {
                existingObject.update(context: self, withJSON: objectJSON)
            } else {
                //_ = T(context: self, json: objectJSON)
                let newObject = T(context: self)
                newObject.update(context: self, withJSON: objectJSON)
            }
        }

        // Delete objects that were deleted from server.
        let deletedObjects = localDates.subtracting(remoteDates)

        // TESTING
        //log.debug("remote: \(remoteDates) - local: \(localDates)")
        //log.debug("We need to delete: \(deletedObjects)")

        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedObjects)
        do {
            try self.deleteEntities(T.self, filter: fetchPredicate)
        } catch {
            /// TODO: deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}
