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

// MARK: - ManagedSyncableCollection

protocol ManagedSyncableCollection: Managed {
    var dateTimeInterval: TimeInterval { get set }
    var date: Date { get set }
    var storeID: Int32 { get set }
    /// TODO: make context optional since we might not always need it?
    func update(in context: NSManagedObjectContext, with json: JSON)
}

extension ManagedSyncableCollection where Self: NSManagedObject {
    /// TODO: replace with updateOrCreate(with: JSON in: NSManagedObjectContext) which would handle parsing the identifier from the response
    static func findOrCreate(withDate date: Date, withJSON json: JSON, in context: NSManagedObjectContext) -> Self {
        let predicate = NSPredicate(format: "dateTimeInterval == %@", date as NSDate)
        guard let obj: Self = findOrFetch(in: context, matching: predicate) else {
            let newObj: Self = context.insertObject()
            newObj.update(in: context, with: json)
            return newObj
        }
        obj.update(in: context, with: json)
        return obj
    }
    /*
    static func fetchByDate(date: Date, in context: NSManagedObjectContext) -> Self? {
        //let request: NSFetchRequest<Self> = Self.fetchRequest() as! NSFetchRequest<Self>
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        request.predicate = NSPredicate(format: "dateTimeInterval == %@", date as NSDate)
        request.fetchLimit = 2

        do {
            let searchResults = try context.fetch(request)

            switch searchResults.count {
            case 0:
                return nil
            case 1:
                return searchResults[0]
            default:
                log.warning("Found multiple matches: \(searchResults)")
                fatalError("Returned multiple objects, expected max 1")
                //return searchResults[0]
            }

        } catch {
            log.error("Error with request: \(error)")
        }
        return nil
    }

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
            let fetchPredicate = NSPredicate(format: "dateTimeInterval IN %@", deletedObjects)
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

// MARK: - SyncableParent

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
