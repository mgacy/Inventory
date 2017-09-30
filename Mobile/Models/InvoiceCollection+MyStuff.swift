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
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            self.date = date
        } else {
            self.date = Date()
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
        myDict["date"] = self.date.shortDate
        myDict["store_id"] = self.storeID
        return myDict
    }

}

// MARK: - ManagedSyncableCollection

extension InvoiceCollection: ManagedSyncableCollection {

    public var date: Date {
        get {
            return Date(timeIntervalSince1970: dateTimeInterval)
        }
        set {
            dateTimeInterval = newValue.timeIntervalSince1970
        }
    }

    public func update(in context: NSManagedObjectContext, with json: JSON) {

        // Required
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            //dateTimeInterval = date.timeIntervalSince1970
            self.date = date
        } else {
            self.date = Date()
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
            /// NOTE: this relies on conformance to SyncableParent
            syncChildren(in: context, with: invoices)
        }
    }

}

// MARK: - Sync Children

extension InvoiceCollection: SyncableParent {
    typealias ChildType = Invoice

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32 : Invoice]? {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.collection = self
        //addToInvoices(entity)
    }

}
