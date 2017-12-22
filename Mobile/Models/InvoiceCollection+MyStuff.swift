//
//  InvoiceCollection+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension InvoiceCollection: DateFacade {}

// MARK: - Syncable

extension InvoiceCollection: Syncable {
    typealias RemoteType = RemoteInvoiceCollection
    typealias RemoteIdentifierType = Date

    static var remoteIdentifierName: String { return "dateTimeInterval" }

    var remoteIdentifier: RemoteIdentifierType { return Date(timeIntervalSinceReferenceDate: dateTimeInterval) }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        guard let date = record.date.toBasicDate() else {
            /// TODO: find better way of handling error; use SyncError type
            fatalError("Unable to parse date from: \(record)")
        }
        self.dateTimeInterval = date.timeIntervalSinceReferenceDate
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        storeID = Int32(record.storeID)

        switch record.status {
        case .pending:
            self.uploaded = false
        case .completed:
            self.uploaded = true
        }

        // Relationships
        if let invoices = record.invoices {
            syncChildren(with: invoices, in: context)
        }
    }

}

// MARK: - SyncableParent

extension InvoiceCollection: SyncableParent {
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
    }

}

// MARK: - Serialization

extension InvoiceCollection {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["date"] = dateTimeInterval.toPythonDateString()
        myDict["store_id"] = storeID
        return myDict
    }

}

// MARK: - Status

extension InvoiceCollection {

    func updateStatus() {
        guard uploaded == false else {
            //log.debug("InvoiceCollection has already been uploaded.")
            return
        }
        guard let invoices = invoices else {
            //log.debug("InvoiceCollection does not appear to have any Invoices.")
            return
        }
        for any in invoices {
            guard let invoice = any as? Invoice else { fatalError("\(#function) FAILED : wrong type") }
            if invoice.status == InvoiceStatus.pending.rawValue {
                return
            }
        }
        uploaded = true
    }

}
