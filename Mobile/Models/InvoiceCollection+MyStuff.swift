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

        // Set properties
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
                log.error("\(#function)Invalid status")
                self.uploaded = true
            }
        }

        // Add Invoices
        if let invoices = json["invoices"].array {
            for invoiceJSON in invoices {
                _ = Invoice(context: context, json: invoiceJSON, collection: self, uploaded: uploaded)
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

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Set properties
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
                log.error("\(#function)Invalid status")
                self.uploaded = true
            }
        }

        // Add Invoices
        if let invoices = json["invoices"].array {
            for invoiceJSON in invoices {
                _ = Invoice(context: context, json: invoiceJSON, collection: self, uploaded: uploaded)
            }
        }
    }


}
