//
//  InventoryItem+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InventoryItem {
    
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, json: JSON,
                     inventory: Inventory) {
        self.init(context: context)
    
        // Is this the best way to determine whether response is for a new or
        // an existing InventoryItem?
        if json["item"]["id"].int != nil {
            initExisting(context: context, json: json)
        } else {
            initNew(context: context, json: json)
        }
        
        // Relationship
        self.inventory = inventory
    }

    private func initNew(context: NSManagedObjectContext, json: JSON) {

        if let itemID = json["id"].int32 {
            self.itemID = itemID
            if let item = context.fetchWithRemoteID(Item.self, withID: itemID) {
                self.item = item
            } else {
                log.warning("\(#function) : unable to fetch Item with remoteID \(itemID) for \(self)")
            }
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let categoryID = json["category_id"].int32 {
            self.categoryID = categoryID
        }
    }
    
    private func initExisting(context: NSManagedObjectContext, json: JSON) {

        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["item"]["name"].string {
            self.name = name
        }
        if let itemID = json["item"]["id"].int32 {
            self.itemID = itemID
            self.item = context.fetchWithRemoteID(Item.self, withID: itemID)
        }
        if let categoryID = json["item"]["category"]["id"].int32 {
            self.categoryID = categoryID
        }
        
        //if let quantity = json["quantity"].double {
        //    self.quantity = Int32(quantity)
        //}
        // if let unitID = json["unit_id"].int {
    }
    
    public func serialize() -> [String: Any] {
        var itemDict: [String: Any] = [
            "item_id": Int(self.itemID),
            "quantity": 0.0
        ]
        
        guard let items = self.items else {
            return itemDict
        }

        var subTotal = 0.0
        for case let item as InventoryLocationItem in items where item.quantity != nil {
            subTotal += Double(item.quantity!)
        }
        itemDict["quantity"] = subTotal
        
        return itemDict
    }
    
}
