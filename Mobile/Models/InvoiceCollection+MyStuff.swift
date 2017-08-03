//
//  InvoiceCollection+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InvoiceCollection {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)

        /// TODO: simply call `.update()`

        // Required
        if let date = json["date"].string {
            self.date = date
        } else {
            self.date = Date().shortDate
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        /// TODO: switch to `status` enum
        if let statusString = json["status"].string {
            switch statusString {
            case "pending":
                self.uploaded = false
            case "complete":
                self.uploaded = true
            default:
                log.error("\(#function) - invalid status: \(statusString)")
                self.uploaded = true
            }
        }

        // Relationships
        if let invoices = json["invoices"].array {
            for invoiceJSON in invoices {
                _ = Invoice(context: context, json: invoiceJSON, parent: self)
                //let new = Invoice(context: context, json: invoiceJSON)
                //new.collection = self
            }
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()

        /// TODO: handle conversion from NSDate to string
        myDict["date"] = self.date
        myDict["store_id"] = self.storeID

        return myDict
    }

    // MARK: - Update Existing

    func updateExisting(context: NSManagedObjectContext, json: JSON) {

        // Iterate over Invoices
        for (_, item) in json {
            _ = Invoice(context: context, json: item, collection: self, uploaded: true)
        }
    }

    // MARK: -

    static func fetchByDate(context: NSManagedObjectContext, date: String) -> InvoiceCollection? {
        //let predicate = NSPredicate(format: "date == %@", date)
        //return context.fetchSingleEntity(InvoiceCollection.self, matchingPredicate: predicate)

        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date)

        do {
            let searchResults = try context.fetch(request)

            switch searchResults.count {
            case 0:
                return nil
            case 1:
                return searchResults[0]
            default:
                log.warning("Found multiple matches: \(searchResults)")
                return searchResults[0]
            }

        } catch {
            log.error("Error with request: \(error)")
        }
        return nil
    }
}

// The extension already offers a default implementation; we will use that
//extension InvoiceCollection: SyncableCollection {}

// MARK: - NEW

extension InvoiceCollection: ManagedSyncableCollection {

    public func update(in context: NSManagedObjectContext, with json: JSON) {

        // Required
        if let date = json["date"].string {
            self.date = date
        } else {
            self.date = Date().shortDate
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        /// TODO: switch to `status` enum
        if let statusString = json["status"].string {
            switch statusString {
            case "pending":
                self.uploaded = false
            case "complete":
                self.uploaded = true
            default:
                log.error("\(#function) - invalid status: \(statusString)")
                self.uploaded = true
            }
        }

        // Relationships
        if let invoices = json["invoices"].array {
            syncChildren(in: context, with: invoices)
            //for invoiceJSON in invoices {
            //    _ = Invoice(context: context, json: invoiceJSON, parent: self)
            //    //let new = Invoice(context: context, json: invoiceJSON)
            //    //new.collection = self
            //}
        }
    }

}

// MARK: - Sync Children

extension InvoiceCollection: SyncableParent {
    typealias ChildType = Invoice

    func syncChildren(in context: NSManagedObjectContext, with json: [JSON]) {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            log.error("\(#function) FAILED : unable to create dictionary for \(ChildType.self)"); return
        }

        log.debug("objectDict: \(objectDict)")
        let localObjects = Set(objectDict.keys)
        var remoteObjects = Set<Int32>()

        for objectJSON in json {
            guard let objectID = objectJSON["id"].int32 else {
                log.warning("\(#function) : unable to get date from \(objectJSON)"); continue
            }
            remoteObjects.insert(objectID)

            // Find + update / create Items
            if let existingObject = objectDict[objectID] {
                existingObject.update(context: context, withJSON: objectJSON)
                //log.debug("existingObject: \(existingObject)")
            } else {
                let newObject = ChildType(context: context)
                newObject.collection = self
                newObject.update(context: context, withJSON: objectJSON)
                //log.debug("newObject: \(newObject)")
            }
        }
        log.debug("\(ChildType.self) - remote: \(remoteObjects) - local: \(localObjects)")

        // Delete objects that were deleted from server.
        let deletedObjects = localObjects.subtracting(remoteObjects)
        deleteChildren(deletedObjects: deletedObjects, context: context)
        /*
        if !deletedObjects.isEmpty {
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
        */
    }

}
