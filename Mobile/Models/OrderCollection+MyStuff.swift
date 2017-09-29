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

    // MARK: - Serialization
    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        myDict["date"] = self.date.stringFromDate()

        // ...

        return myDict
    }

    // MARK: - Update Existing

//    func updateExisting(context: NSManagedObjectContext, json: JSON) {
//        guard let orders = json["orders"].array else {
//            log.error("\(#function) FAILED : unable to get orders from JSON"); return
//        }
//
//        // Iterate over Orders
//        for orderJSON in orders {
//            _ = Order(context: context, json: orderJSON, collection: self, uploaded: true)
//        }
//    }

    // MARK: -

//    static func fetchByDate(context: NSManagedObjectContext, date: String) -> OrderCollection? {
//        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
//        request.predicate = NSPredicate(format: "date == %@", date)
//
//        do {
//            let searchResults = try context.fetch(request)
//
//            switch searchResults.count {
//            case 0:
//                return nil
//            case 1:
//                return searchResults[0]
//            default:
//                log.warning("Found multiple matches: \(searchResults)")
//                //fatalError("Returned multiple objects, expected max 1")
//                return searchResults[0]
//            }
//
//        } catch {
//            log.error("Error with request: \(error)")
//        }
//        return nil
//    }
}

extension OrderCollection {

    func updateStatus() {
        log.debug("\(#function) starting ...")
        guard uploaded == false else {
            log.debug("OrderCollection has already been uploaded.")
            return
        }
        guard let orders = orders else {
            log.debug("OrderCollection does not appear to have any Orders.")
            return
        }
        for order in orders {
            // swiftlint:disable:next for_where
            if (order as? Order)?.uploaded == false {
                log.debug("Order has not been uploaded")
                return
            }
        }

        log.debug("It looks like all orders have been uploaded; we should change status")
        uploaded = true
    }

}

// MARK: - ManagedSyncableCollection

extension OrderCollection: ManagedSyncableCollection {

    public var date: Date {
        get {
            return Date(timeIntervalSince1970: dateA)
        }
        set {
            dateA = newValue.timeIntervalSince1970
        }
    }

    public func update(in context: NSManagedObjectContext, with json: JSON) {

        // Set properties
        if let dateString = json["date"].string,
           let date = dateString.toBasicDate() {
            //dateA = date.timeIntervalSince1970
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
        entity.date = self.date
    }

}
