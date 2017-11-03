//
//  Syncable.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/15/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData
import SwiftyJSON

protocol NewSyncable: Managed {
    /// TODO: rename `RemoteType` as `RemoteRecordType`?
    associatedtype RemoteType: RemoteRecord
    associatedtype RemoteIdentifierType: Hashable

    static var remoteIdentifierName: String { get }
    var remoteIdentifier: RemoteIdentifierType { get }

    /// TODO: should these all throw?
    //static func updateOrCreate(with: RemoteType, in: NSManageObjectContext) -> Self
    static func sync(with: [RemoteType], in: NSManagedObjectContext)
    func update(with: RemoteType, in: NSManagedObjectContext)
}

extension NewSyncable where Self: NSManagedObject {

    static var remoteIdentifierName: String { return "remoteID" }

    init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        self.setValue(record.syncIdentifier, forKey: Self.remoteIdentifierName)
        self.update(with: record, in: context)
    }

    static func updateOrCreate<R>(with record: RemoteType, in context: NSManagedObjectContext) -> Self
        where R == Self.RemoteIdentifierType, R == RemoteType.SyncIdentifierType {

            let remoteIdentifier = record.syncIdentifier
            let predicate = NSPredicate(format: "\(remoteIdentifierName) == \(remoteIdentifier)")
            if let existingObject = findOrFetch(in: context, matching: predicate) {
                existingObject.update(with: record, in: context)
                return existingObject
            } else {
                let newObject = Self(with: record, in: context)
                /*
                let newObject: Self = context.insertObject()
                newObject.setValue(record.syncIdentifier, forKey: remoteIdentifierName)
                newObject.update(with: record, in: context)
                 */
                return newObject
            }
    }

    static func fetchEntityDict<T>(in context: NSManagedObjectContext, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [T: Self] where T == Self.RemoteIdentifierType {

        let request = NSFetchRequest<Self>(entityName: Self.entityName)

        /*
         Set returnsObjectsAsFaults to false to gain a performance benefit if you know
         you will need to access the property values from the returned objects.
         */
        request.returnsObjectsAsFaults = asFaults
        request.predicate = predicate
        request.relationshipKeyPathsForPrefetching = relationships

        do {
            let fetchedResult = try context.fetch(request)
            return fetchedResult.toDictionary { $0.remoteIdentifier }
        } catch let error {
            log.error(error.localizedDescription)
            throw error
        }
    }

    static func fetchWithRemoteIdentifier<T>(_ identifier: T, in context: NSManagedObjectContext) -> Self?
        where T == Self.RemoteIdentifierType {
            let predicate = NSPredicate(format: "\(Self.remoteIdentifierName) == \(identifier)")
            // NOTE: this doesn't produce an error for multiple matches
            return findOrFetch(in: context, matching: predicate)
    }

    /// TODO: add `throws`?
    /// TODO: add predicate and configuration block `configure: () -> Void = { _ in }`; this could cover most of NewSyncableParent
    static func sync<R>(with records: [RemoteType], in context: NSManagedObjectContext)
        where R == Self.RemoteIdentifierType, R == RemoteType.SyncIdentifierType {
            guard let objectDict: [R: Self] = try? fetchEntityDict(in: context) else {
                log.error("\(#function) FAILED : unable to create dictionary for \(self)"); return
            }

            let localIDs: Set<R> = Set(objectDict.keys)
            var remoteIDs = Set<R>()

            for record in records {
                let objectID = record.syncIdentifier
                remoteIDs.insert(objectID)

                // Find + update / create Items
                if let existingObject = objectDict[objectID] {
                    existingObject.update(with: record, in: context)
                    //log.debug("existingObject: \(existingObject)")
                } else {
                    let newObject = Self(with: record, in: context)
                    /// TODO: add newObject to localIDs?
                    log.debug("newObject: \(newObject)")
                }
                /*
                let object = objectDict[objectID] ?? Self.init(context: context)
                object.update(with: record, in: managedObjectContext)
                 */
            }

            log.debug("\(self) - remote: \(remoteIDs) - local: \(localIDs)")

            // Delete objects that were deleted from server. We filter remoteID 0
            // since that is the default value for new objects
            /// TODO: switch based on remoteIdentifierName instead?
            let deletedObjects: Set<R>
            switch R.self {
            case is Int32.Type:
                deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 as? Int32 != 0 }
            case is Int.Type:
                deletedObjects = localIDs.subtracting(remoteIDs).filter { $0 as? Int != 0 }
            default:
                deletedObjects = localIDs.subtracting(remoteIDs)
            }

            if !deletedObjects.isEmpty {
                log.debug("We need to delete: \(deletedObjects)")
                let fetchPredicate = NSPredicate(format: "\(Self.remoteIdentifierName) IN %@", deletedObjects)
                do {
                    try context.deleteEntities(self, filter: fetchPredicate)
                } catch {
                    /// TODO: deleteEntities(_:filter) already logs the error
                    let updateError = error as NSError
                    log.error("\(updateError), \(updateError.userInfo)")
                    //throw updateError?
                }
            }
    }

}

// MARK: - Syncable
// NOTE: Unit still conforms to Syncable

public protocol Syncable {
    var remoteID: Int32 { get set }

    //convenience init(context: NSManagedObjectContext, representation: Any)
    func update(context: NSManagedObjectContext, withJSON json: JSON)
}
