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
        if let date = json["date"].string {
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

        /// TODO: handle conversion from NSDate to string
        myDict["date"] = self.date

        // ...

        return myDict
    }

    // MARK: - Update Existing

    func updateExisting(context: NSManagedObjectContext, json: JSON) {
        guard let orders = json["orders"].array else {
            log.error("\(#function) FAILED : unable to get orders from JSON"); return
        }

        // Iterate over Orders
        for orderJSON in orders {
            _ = Order(context: context, json: orderJSON, collection: self, uploaded: true)
        }
    }

    // MARK: -

    static func fetchByDate(context: NSManagedObjectContext, date: String) -> OrderCollection? {
        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
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
                //fatalError("Returned multiple objects, expected max 1")
                return searchResults[0]
            }

        } catch {
            log.error("Error with request: \(error)")
        }
        return nil
    }
}

// The extension already offers a default implementation; we will use that
extension OrderCollection: SyncableCollection {}

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
