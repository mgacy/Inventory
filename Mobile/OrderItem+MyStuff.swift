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
            if let item = context.fetchWithRemoteID(Item.self, withID: itemID) {
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
