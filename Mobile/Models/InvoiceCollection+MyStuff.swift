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

// MARK: - Serialization

extension InvoiceCollection {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["date"] = dateTimeInterval.toPythonDateString()
        myDict["store_id"] = storeID
        return myDict
    }

}

extension InvoiceCollection: DateFacade {}

// MARK: - NewSyncable

extension InvoiceCollection: NewSyncable {
    typealias RemoteType = RemoteInvoiceCollection
    typealias RemoteIdentifierType = Date

    static var remoteIdentifierName: String { return "dateTimeInterval" }

    var remoteIdentifier: RemoteIdentifierType { return Date(timeIntervalSinceReferenceDate: dateTimeInterval) }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        if let date = record.date.toBasicDate() {
            self.dateTimeInterval = date.timeIntervalSinceReferenceDate
        } else {
            /// TODO: find better way of handling error
            fatalError("Unable to parse date from: \(record)")
        }
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //if let date = record.date.toBasicDate() {
        //    self.dateTimeInterval = date.timeIntervalSinceReferenceDate
        //}
        storeID = Int32(record.storeID)

        /// TODO: switch to `status` enum
        switch record.status {
        case "pending":
            self.uploaded = false
        case "complete":
            self.uploaded = true
        default:
            log.error("\(#function) - invalid status: \(record.status)")
            self.uploaded = true
        }

        // Relationships
        if let invoices = record.invoices {
            syncChildren(with: invoices, in: context)
        }
    }

}

// MARK: - NewSyncableParent

extension InvoiceCollection: NewSyncableParent {
    typealias ChildType = Invoice

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: Invoice]? {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? ChildType.fetchEntityDict(in: context, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.collection = self
        //addToInvoices(entity)
    }

}
