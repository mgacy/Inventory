//
//  NSManagedObjectContext+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

// swiftlint:disable force_cast

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
            // throw error?
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
            // TODO: provide better error info?
            log.error(error.localizedDescription)
            throw error
        }
    }

}

// MARK: - Delete
extension NSManagedObjectContext {

    func deleteEntities<T: NSManagedObject>(_ entityClass: T.Type, filter: NSPredicate? = nil) throws {

        // TODO: actually throw on exception?

        // Ensure any changes are first pushed to the persistent store
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                let saveError = error as NSError
                log.error("\(saveError), \(saveError.userInfo)")
                // throw saveError?
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
            log.verbose("Batch deleted \(batchDeleteResult.result!) \(entityClass.self) records.")

            // As the request directly interacts with the persistent store, we need need to reset the context for it to be aware of the changes
            self.reset()
        } catch {
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
            // throw updateError?
        }
    }

}

// MARK: - Save
// objc.io - Core Data
extension NSManagedObjectContext {

    public func saveOrRollback() -> Bool {
        // TODO: proceed only if self.hasChanges?
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
