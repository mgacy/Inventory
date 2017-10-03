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

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "dateTimeInterval", ascending: false)]
    }
    /*
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
     */
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
