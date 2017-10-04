//
//  OrderItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension OrderItem {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, order: Order) {
        self.init(context: context)

        // Properties

        if let itemID = json["item"]["id"].int32 {
            self.itemID = itemID
        }

        if let onHand = json["inventory"].double {
            self.onHand = onHand //as NSNumber?
        }

        // par
        if let par = json["par"].double {
            self.par = par
        }
        if let parUnitID = json["par_unit_id"].int32 {
            self.parUnit = context.fetchWithRemoteID(Unit.self, withID: parUnitID)
        }

        // minOrder
        if let minOrder = json["min_order"].double {
            self.minOrder = minOrder
            self.quantity = minOrder as NSNumber?
        }
        if let minOrderUnitID = json["min_order_unit_id"].int32 {
            self.minOrderUnit = context.fetchWithRemoteID(Unit.self, withID: minOrderUnitID)
        }

        // order
        if let order = json["quantity"].double {
            self.quantity = order as NSNumber?
        }
        // Accomodate differences between response for new and existing Orders
        if let orderUnitID = json["unit_id"].int32 {
            self.orderUnit = context.fetchWithRemoteID(Unit.self, withID: orderUnitID)
        } else if let orderUnitID = json["unit"]["id"].int32 {
            self.orderUnit = context.fetchWithRemoteID(Unit.self, withID: orderUnitID)
        }

        // Relationships

        if let itemID = json["item"]["id"].int32 {
            if let item = context.fetchWithRemoteIdentifier(Item.self, identifier: itemID) {
                self.item = item
            }
        }

        self.order = order
    }

    // MARK: - Serialization

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

// MARK: - ManagedSyncable

extension OrderItem: ManagedSyncable {

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Required

        // Optional
        // itemID
        // minOrder
        // onHand
        // par
        // quantity
        // remoteID

        if let itemID = json["item"]["id"].int32 { self.itemID = itemID }
        if let minOrder = json["min_order"].double { self.minOrder = minOrder }
        if let onHand = json["inventory"].double { self.onHand = onHand }
        if let par = json["par"].double { self.par = par }
        /// TODO: should quantity be a scalar?
        if let quantity = json["quantity"].double { self.quantity = quantity as NSNumber }
        if let remoteID = json["id"].int32 { self.remoteID = remoteID }

        // Relationships
        // item
        // minOrderUnit
        // order
        // orderUnit
        // parUnit

        if let itemID = json["item"]["id"].int32 {
            if let item = context.fetchWithRemoteIdentifier(Item.self, identifier: itemID) {
                self.item = item
            } else {
                log.error("Unable to find Item for remoteID \(itemID)")
            }
        }
        if let remoteMinOrderUnitID = json["min_order_unit_id"].int32 {
            //let localMinOrderUnitID = minOrderUnit?.remoteID
            if remoteMinOrderUnitID != minOrderUnit?.remoteID {
                //log.debug("Update minOrderUnit")
                minOrderUnit = context.fetchWithRemoteID(Unit.self, withID: remoteMinOrderUnitID)
            }
        }
        //if let remoteOrderUnitID = json["unit_id"].int32 {
        if let remoteOrderUnitID = json["unit"]["id"].int32 {
            //let localOrderUnitID = orderUnit?.remoteID
            if remoteOrderUnitID != orderUnit?.remoteID {
                //log.debug("Update orderUnit")
                orderUnit = context.fetchWithRemoteID(Unit.self, withID: remoteOrderUnitID)
            }
        }
        if let remoteParUnitID = json["par_unit_id"].int32 {
            //let localParUnitID = orderUnit?.remoteID
            if remoteParUnitID != orderUnit?.remoteID {
                //log.debug("Update parUnit")
                parUnit = context.fetchWithRemoteID(Unit.self, withID: remoteParUnitID)
            }
        }
    }
}
