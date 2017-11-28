//
//  OrderItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

// MARK: - Syncable

extension OrderItem: Syncable {
    typealias RemoteType = RemoteOrderItem
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {

        // Required

        // Optional
        // itemID = Int32(record.item.remoteID)
        // remoteID = record.syncIdentifier
        minOrder = record.minOrder ?? -1
        onHand = record.inventory ?? -1
        par = record.par ?? -1
        // NOTE: old .init() setminOrder and quantity to json["min_order"]
        if let quantity = record.quantity {
            self.quantity = quantity as NSNumber
        }

        // Relationships
        // order
        // item
        if Int32(record.item.remoteID) != self.item?.remoteID {
            let predicate = NSPredicate(format: "remoteID == \(Int32(record.item.remoteID))")
            if let existingObject = Item.findOrFetch(in: context, matching: predicate) {
                self.item = existingObject
            } else {
                log.error("\(#function) FAILED : unable to fetch Item \(record.item)")
            }
        }
        // orderUnit
        if record.unit.syncIdentifier != self.orderUnit?.remoteID {
            guard let newUnit = Unit.fetchWithRemoteIdentifier(record.unit.syncIdentifier, in: context) else {
                log.error("\(#function) FAILED : unable to fetch Item \(record.unit)"); return
            }
            self.orderUnit = newUnit
        }
        // minOrderUnit
        if let minOrderUnitId = record.minOrderUnitId {
            if Int32(minOrderUnitId) != self.minOrderUnit?.remoteID {
                self.minOrderUnit = Unit.fetchWithRemoteIdentifier(Int32(minOrderUnitId), in: context)
            }
        }
        // parUnit
        if let parUnitId = record.parUnitId {
            if Int32(parUnitId) != self.parUnit?.remoteID {
                self.parUnit = Unit.fetchWithRemoteIdentifier(Int32(parUnitId), in: context)
            }
        }
    }

}

// MARK: - Serialization

extension OrderItem {

    func serialize() -> [String: Any]? {
        if self.quantity == 0 {
            return nil
        }

        var myDict = [String: Any]()

        myDict["item_id"] = self.item?.remoteID
        myDict["order_quant"] = self.quantity
        myDict["order_unit_id"] = self.orderUnit?.remoteID

        return myDict
    }

}
