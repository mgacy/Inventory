//
//  Syncable.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/15/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

// MARK: - Syncable
public protocol Syncable {

    // https://gist.github.com/capttaco/adb38e0d37fbaf9c004e
    //associatedtype SyncableType: NSManagedObject = Self

    var remoteID: Int32 { get set }

    //convenience init(context: NSManagedObjectContext, representation: Any)
    //func update(with json: Any, in context: NSManagedObjectContext)
    func update(context: NSManagedObjectContext, withJSON json: JSON)
}

// MARK: - ManagedSyncable

protocol ManagedSyncable: Managed, Syncable {}

extension ManagedSyncable where Self: NSManagedObject {

    static func findOrCreate(withID id: Int32, withJSON json: JSON, in context: NSManagedObjectContext) -> Self {
        let predicate = NSPredicate(format: "remoteID == \(id)")
        guard let obj: Self = findOrFetch(in: context, matching: predicate) else {
            //log.debug("Creating \(Self.self) \(id)")
            let newObj: Self = context.insertObject()
            newObj.update(context: context, withJSON: json)
            return newObj
        }
        //log.debug("Updating \(Self.self) \(id)")
        obj.update(context: context, withJSON: json)
        return obj
    }

}

// MARK: - SyncableCollection
@objc public protocol SyncableCollection {
    var date: String? { get set }
    var storeID: Int32 { get set }
    var uploaded: Bool { get set }
}

extension SyncableCollection where Self : NSManagedObject {

    func update(context: NSManagedObjectContext, withJSON json: JSON) {
        if let date = json["date"].string {
            self.date = date
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        //self.uploaded = uploaded
    }

    func update(context: NSManagedObjectContext, withJSON json: JSON, uploaded: Bool) {
        if let date = json["date"].string {
            self.date = date
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        self.uploaded = uploaded
    }

}

// MARK: - New (ManagedSyncableCollection) -

public protocol NewSyncableCollection {
    var date: String? { get set }
    // var date: Date { get set }
    var storeID: Int32 { get set }
    /// TODO: make context optional since we might not always need it?
    func update(in context: NSManagedObjectContext, with json: JSON)
}

protocol ManagedSyncableCollection: Managed, NewSyncableCollection {}

extension ManagedSyncableCollection where Self: NSManagedObject {

    static func findOrCreate(withDate date: String, withJSON json: JSON, in context: NSManagedObjectContext) -> Self {
        let predicate = NSPredicate(format: "date == \(date)")
        guard let obj: Self = findOrFetch(in: context, matching: predicate) else {
            let newObj: Self = context.insertObject()
            newObj.update(in: context, with: json)
            return newObj
        }
        obj.update(in: context, with: json)
        return obj
    }
    /*
    static func sync(withJSON json: JSON, in context: NSManagedObjectContext) throws {
        let fetchPredicate: NSPredicate? = nil
        guard let objectDict = try? context.fetchCollectionDict(self, matching: fetchPredicate) else {
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
                existingObject.update(in: context, with: objectJSON)
            } else {
                let newObject: Self = context.insertObject()
                newObject.update(in: context, with: objectJSON)
            }
        }
        log.debug("\(self) - remote: \(remoteDates) - local: \(localDates)")

        // Delete objects that were deleted from server.
        let deletedObjects = localDates.subtracting(remoteDates)
        if !deletedObjects.isEmpty {
            log.debug("We need to delete: \(deletedObjects)")
            let fetchPredicate = NSPredicate(format: "date IN %@", deletedObjects)
            do {
                try context.deleteEntities(self, filter: fetchPredicate)
            } catch {
                /// TODO: deleteEntities(_:filter) already prints the error
                let updateError = error as NSError
                log.error("\(updateError), \(updateError.userInfo)")
            }
        }
    }
    */
}

// MARK: NSManagedObjectContext - ManagedSyncableCollection

extension NSManagedObjectContext {

    func fetchByDate<T: ManagedSyncableCollection>(_ entity: T.Type, withDate date: String) -> T? where T: NSManagedObject {
        // swiftlint:disable:next force_cast
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
                //return searchResults[0]
            }

        } catch let error {
            log.error("\(#function) FAILED : error with request: \(error)")
        }
        return nil
    }

    func fetchCollectionDict<T: ManagedSyncableCollection>(_ entityClass: T.Type, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [String: T] where T: NSManagedObject {

        let request: NSFetchRequest<T>
        if #available(iOS 10.0, *) {
            // swiftlint:disable:next force_cast
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

    func syncCollections<T: ManagedSyncableCollection>(_ entity: T.Type, withJSON json: JSON) throws where T: NSManagedObject {
        let fetchPredicate: NSPredicate? = nil
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
                existingObject.update(in: self, with: objectJSON)
            } else {
                let newObject = T(context: self)
                newObject.update(in: self, with: objectJSON)
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
            }
        }
    }

}

// MARK: - New (SyncableParent) -

/// TODO: rename to reference relationships
protocol SyncableParent: class, NSFetchRequestResult {
    associatedtype ChildType: ManagedSyncable

    func syncChildren(in: NSManagedObjectContext, with: [JSON])
    func fetchChildDict(in: NSManagedObjectContext) -> [Int32: ChildType]?
    func addToChildren(_: ChildType)
}

extension SyncableParent where ChildType: NSManagedObject {

    func syncChildren(in context: NSManagedObjectContext, with json: [JSON]) {
        guard let objectDict = fetchChildDict(in: context) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(ChildType.self)"); return
        }
        //log.debug("objectDict: \(objectDict)")

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
                addToChildren(newObject)
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
        guard !deletedObjects.isEmpty else {
            return
        }
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
