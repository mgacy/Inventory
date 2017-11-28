//
//  NSManagedObjectContext+Syncable.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData

// swiftlint:disable force_cast

extension NSManagedObjectContext {

    func fetchWithRemoteIdentifier<T: Syncable, I>(_ entity: T.Type, identifier id: I) -> T? where T: NSManagedObject, I == T.RemoteIdentifierType {
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

    func fetchEntityDict<T: Syncable, I>(_ entityClass: T.Type, matching predicate: NSPredicate? = nil, prefetchingRelationships relationships: [String]? = nil, returningAsFaults asFaults: Bool = false) throws -> [I: T] where T: NSManagedObject, I == T.RemoteIdentifierType {

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

}
