//
//  OrderCollection+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension OrderCollection: DateFacade {}

// MARK: - Syncable

extension OrderCollection: Syncable {
    typealias RemoteType = RemoteOrderCollection
    typealias RemoteIdentifierType = Date

    static var remoteIdentifierName: String { return "dateTimeInterval" }

    var remoteIdentifier: RemoteIdentifierType { return Date(timeIntervalSinceReferenceDate: dateTimeInterval) }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        guard let date = record.date.toBasicDate() else {
            /// TODO:find better way of handling error; use SyncError type
            fatalError("Unable to parse date from: \(record)")
        }
        self.dateTimeInterval = date.timeIntervalSinceReferenceDate
        self.uploaded = true
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        self.storeID = Int32(record.storeID)
        if let inventoryID = record.inventoryId { self.inventoryID = Int32(inventoryID) }

        /// TODO: handle `uploaded`

        /// Relationships
        if let orders = record.orders {
            syncChildren(with: orders, in: context)
        }

        updateStatus()
    }

}

// MARK: - SyncableParent

extension OrderCollection: SyncableParent {
    typealias ChildType = Order

    /// TODO: handle remoteID == 0 on new Orders
    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: Order]? {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? ChildType.fetchEntityDict(in: context, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.collection = self
        entity.date = self.dateTimeInterval
    }

}

// MARK: - Serialization

extension OrderCollection {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["date"] = dateTimeInterval.toPythonDateString()

        // ...

        return myDict
    }

}

// MARK: - Status

extension OrderCollection {

    func updateStatus() {
        //log.debug("\(#function) starting ...")
        guard uploaded == false else {
            //log.debug("OrderCollection has already been uploaded.")
            return
        }
        guard let orders = orders else {
            //log.debug("OrderCollection does not appear to have any Orders.")
            return
        }
        for order in orders {
            // swiftlint:disable:next for_where
            if (order as? Order)?.uploaded == false {
                //log.debug("Order has not been uploaded")
                return
            }
        }

        //log.debug("It looks like all orders have been uploaded; we should change status")
        uploaded = true
    }

}
