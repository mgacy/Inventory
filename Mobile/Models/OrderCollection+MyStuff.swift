//
//  OrderCollection+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension OrderCollection {

    // MARK: - Lifecycle
    /*
    convenience init(context: NSManagedObjectContext, json: JSON, uploaded: Bool = false) {
        self.init(context: context)

        // Set properties
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            self.date = date
        }
        if let inventoryID = json["inventory_id"].int32 {
            self.inventoryID = inventoryID
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        self.uploaded = uploaded

        // Add Orders
        if let orders = json["orders"].array {
            for orderJSON in orders {
                _ = Order(context: context, json: orderJSON, collection: self, uploaded: uploaded)
            }
        }
    }
     */
    // MARK: - Serialization
    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["date"] = dateTimeInterval.toPythonDateString()

        // ...

        return myDict
    }

}

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

extension OrderCollection: DateFacade {}

// MARK: - ManagedSyncableCollection
/*
extension OrderCollection: ManagedSyncableCollection {

    public func update(in context: NSManagedObjectContext, with json: JSON) {

        // Set properties
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            //dateTimeInterval = date.timeIntervalSince1970
            self.date = date
        }
        if let inventoryID = json["inventory_id"].int32 {
            self.inventoryID = inventoryID
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }

        /// TODO: handle `uploaded`
        //self.uploaded = uploaded

        // Add Orders
        if let orders = json["orders"].array {
            /// NOTE: this relies on conformance to SyncableParent
            syncChildren(in: context, with: orders)
        }

        updateStatus()
    }

}

// MARK: - Sync Children

extension OrderCollection: SyncableParent {
    typealias ChildType = Order

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32 : Order]? {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.collection = self
        entity.date = self.dateTimeInterval
    }

}
*/
// MARK: - NewSyncable

extension OrderCollection: NewSyncable {
    typealias RemoteType = RemoteOrderCollection
    typealias RemoteIdentifierType = Date

    static var remoteIdentifierName: String { return "dateTimeInterval" }

    var remoteIdentifier: RemoteIdentifierType { return Date(timeIntervalSinceReferenceDate: dateTimeInterval) }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        /// TODO: since this is the remoteIdentifier, should we remove this from `update()`?
        /// TODO: is there an actual case where this would fail? Swtich to using `guard` or set to `Date()` on failure?
        if let date = record.date.toBasicDate() {
            self.dateTimeInterval = date.timeIntervalSinceReferenceDate
        }
        self.storeID = Int32(record.storeID)
        if let inventoryID = record.inventoryId { self.inventoryID = Int32(inventoryID) }

        /// TODO: handle `uploaded`

        // Relationships
        if let orders = record.orders {
            syncChildren(with: orders, in: context)
        }
    }

}

// MARK: - NewSyncableParent
extension OrderCollection: NewSyncableParent {
    typealias ChildType = Order

    /// TODO: handle remoteID == 0 on new Orders
    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32 : Order]? {
        let fetchPredicate = NSPredicate(format: "collection == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: ChildType) {
        entity.collection = self
    }

}
