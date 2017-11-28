//
//  Order+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

@objc public enum OrderStatus: Int16 {
    case incomplete = 0
    case empty      = 1
    case pending    = 2
    // case reviewed - for empty but acceptd as such (that's right, no order this week)?
    case placed     = 3
    case uploaded   = 4

    //static func asString(raw: Int16) -> String? {}

    //init?(string: String) {}

}

// MARK: - Syncable

extension Order: Syncable {
    typealias RemoteType = RemoteOrder
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
        // NOTE: old .init had `if !uploaded { updateStatus() }`
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        // Required
        if let date = record.date.toBasicDate() {
            self.date = date.timeIntervalSinceReferenceDate
        }
        // FIXME: get status from record
        status = OrderStatus.uploaded.rawValue
        // placed

        // Optional
        // remoteID = record.syncIdentifier
        // uploaded

        // Unimplemented
        // cost = record.cost

        // Relationships
        // collection
        // store
        if record.vendor.syncIdentifier != vendor?.remoteIdentifier {
            vendor = Vendor.updateOrCreate(with: record.vendor, in: context)
        }
        syncChildren(with: record.items, in: context)

        /// TODO: handle status
    }

}

// MARK: - SyncableParent

extension Order: SyncableParent {
    typealias ChildType = OrderItem

    func fetchChildDict(in context: NSManagedObjectContext) -> [Int32: OrderItem]? {
        let fetchPredicate = NSPredicate(format: "order == %@", self)
        guard let objectDict = try? ChildType.fetchEntityDict(in: context, matching: fetchPredicate) else {
            return nil
        }
        return objectDict
    }

    func updateParent(of entity: OrderItem) {
        entity.order = self
    }

}

// MARK: - Serialization

extension Order {

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        //myDict["order_date"] = self.collection?.dateTimeInterval.toPythonDateString()
        myDict["order_date"] = date.toPythonDateString()
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

}

// MARK: - Order Generation

extension Order {

    /// TODO: move into separate object
    func getOrderMessage() -> String? {
        guard let items = self.items else { return nil }

        var messageItems: [String] = []
        for case let item as OrderItem in items {
            guard let quantity = item.quantity else { continue }

            if quantity.doubleValue > 0.0 {
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

// MARK: - Status

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
