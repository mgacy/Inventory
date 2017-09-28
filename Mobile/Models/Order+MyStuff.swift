//
//  Order+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc public enum OrderStatus: Int16 {
    case incomplete = 0
    case empty      = 1
    case pending    = 2
    // case reviewed - for empty but acceptd as such (that's right, no order this week)?
    case placed     = 3
    case uploaded   = 4
}

extension Order {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, collection: OrderCollection, uploaded: Bool = false) {
        self.init(context: context)

        // Properties
        // if let orderCost = json["order_cost"].float {}
        if let dateString = json["order_date"].string,
           let date = dateString.toBasicDate() {
            self.date = date
        }
        if uploaded {
            self.status = OrderStatus.uploaded.rawValue
        } else {
            self.status = OrderStatus.pending.rawValue
        }

        // Missing properties
        // placed
        // remoteID
        // vendorID
        // store

        // Relationships
        self.collection = collection
        if let vendorID = json["vendor"]["id"].int32 {
            self.vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID)
        }

        /*
        // Rep
        if json["vendor"]["rep"].array != nil {
            // rep = json["vendor"]["rep"]["name"].string {}
            // repEmail = json["vendor"]["rep"]["email"].string {}
            // repPhone = json["vendor"]["rep"]["phone"].int {}
        }
        */

        // OrderItems
        if let items = json["items"].array {
            log.info("Creating OrderItems ...")
            for itemJSON in items {
                _ = OrderItem(context: context, json: itemJSON, order: self)
            }
        }

        if !uploaded {
            updateStatus()
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        //myDict["order_date"] = self.collection?.date
        myDict["order_date"] = self.date.stringFromDate()
        myDict["store_id"] = self.collection?.storeID
        myDict["vendor_id"] = self.vendor?.remoteID

        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            log.warning("\(#function) FAILED : unable to serialize without any OrderItems")
            return myDict
        }

        var itemsArray = [[String: Any]]()
        for case let item as OrderItem in items {
            if let itemDict = item.serialize() {
                itemsArray.append(itemDict)
            }
        }
        myDict["items"] = itemsArray

        return myDict
    }

    // MARK: - Order Generation
    /// TODO: move into separate object
    func getOrderMessage() -> String? {
        guard let items = self.items else { return nil }

        var messageItems: [String] = []
        for case let item as OrderItem in items {
            guard let quantity = item.quantity else { continue }

            if Int(quantity) > 0 {
                guard let name = item.item?.name else { continue }
                messageItems.append("\n\(name) \(quantity) \(item.orderUnit?.abbreviation ?? "")")
            }
        }

        if messageItems.count == 0 { return nil }

        messageItems.sort()
        /// TODO: handle conversion from NSDate to String
        let message = "Order for \(collection?.date.altStringFromDate() ?? ""):\n\(messageItems.joined(separator: ""))"
        log.debug("Order Message: \(message)")
        return message
    }

}

extension Order {

    func updateStatus() {
        guard status != OrderStatus.placed.rawValue,
              status != OrderStatus.uploaded.rawValue else {
                return
        }

        guard let items = items else {
            log.debug("Order appears to be empty")
            status = OrderStatus.empty.rawValue
            return
        }

        var hasOrder = false
        for item in items {
            if let quantity = (item as? OrderItem)?.quantity {
                if quantity.intValue > 0 {
                    hasOrder = true
                }
            } else {
                status = OrderStatus.incomplete.rawValue
                return
            }
        }

        if hasOrder {
            status = OrderStatus.pending.rawValue
        } else {
            log.debug("It looks like we have an empty order.")
            status = OrderStatus.empty.rawValue
        }
    }

}

// MARK: - ManagedSyncable

extension Order: ManagedSyncable {

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {
        log.debug("Updating Order with: \(json)")
        // Required
        // date
        // placed
        // status

        // if let orderCost = json["order_cost"].float {}
        if let dateString = json["order_date"].string,
            let date = dateString.toBasicDate() {
            self.date = date
        }

        // Optional
        // remoteID
        // uploaded
        // vendorID

        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }

        // FIXME: get status from JSON
        self.status = OrderStatus.uploaded.rawValue

        // Relationships
        // collection?
        // items
        // store?
        // vendor?

        if let items = json["items"].array {
            syncChildren(in: context, with: items)
        }

        /// TODO: do we need to handle removal of vendor from remote?
        if let vendorID = json["vendor"]["id"].int32 {
            if vendorID != vendor?.remoteID {
                self.vendor = context.fetchWithRemoteID(Vendor.self, withID: vendorID)
            }
        }

        /// TODO: update status?
    }

}

// MARK: - SyncableParent

extension Order: SyncableParent {
    typealias ChildType = OrderItem

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: ChildType]? {
        let fetchPredicate = NSPredicate(format: "order == %@", self)
        guard let objectDict = try? context.fetchEntityDict(ChildType.self, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func addToChildren(_ entity: ChildType) {
        entity.order = self
        //addToItems(entity)
    }

}
