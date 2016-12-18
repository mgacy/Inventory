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

extension NSManagedObjectContext {

    // MARK: - Insert

    public func insertObject<T : NSManagedObject>(_ entity: T.Type) -> T {
        let newItem = T(context: self)
        return newItem
    }

    public func insertObjectWithJSON<T : Syncable>(_ entity: T.Type, withJSON json: JSON) -> T where T: NSManagedObject {
        let newItem = T(context: self)
        newItem.update(context: self, withJSON: json)
        return newItem
    }

    // MARK: - Fetch

    // NOTE - this requires (1) entity has remoteID and (2) type is Int32
    // TODO - make T require objects conforming to protocol specifying the above requirements?
    public func fetchWithRemoteID<T : NSManagedObject>(_ entity: T.Type, withID id: Int32) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "remoteID == \(id)")
        request.fetchLimit = 2

        do {
            let fetchResults = try self.fetch(request)

            switch fetchResults.count {
            case 0:
                //print("Found 0 matches for remoteID \(id)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                print("\(#function) FAILED: found multiple matches for remoteID \(id): \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }

        } catch let error {
            print("Error with request: \(error)")
        }
        return nil
    }

    public func fetchSingleEntity<T : NSManagedObject>(_ entity: T.Type, matchingPredicate predicate: NSPredicate) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        request.fetchLimit = 2
        
        do {
            let fetchResults = try self.fetch(request)
            
            switch fetchResults.count {
            case 0:
                return nil
            case 1:
                return fetchResults[0]
            default:
                print("\(#function) FAILED: found multiple matches: \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }
        
        } catch let error {
            print("Error with request: \(error)")
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
            print(error.localizedDescription)
            throw error
        }
    }

    func fetchEntityDict<T: Syncable>(_ entityClass: T.Type, matchingPredicate predicate: NSPredicate? = nil) throws -> [Int32: T] where T: NSManagedObject {

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
        request.returnsObjectsAsFaults = false
        request.predicate = predicate

        //let fetchedResult = try self.fetch(request)
        //return fetchedResult
        do {
            let fetchedResult = try self.fetch(request)
            let objectDict = fetchedResult.toDictionary { $0.remoteID }
            return objectDict
        } catch let error {
            print(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Delete

    func deleteEntities<T: NSManagedObject>(_ entityClass: T.Type, filter: NSPredicate? = nil) throws {

        // We need to make sure that any changes are first pushed to the persistent store
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
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

            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")

            // Reset Managed Object Context
            self.reset()

        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}
