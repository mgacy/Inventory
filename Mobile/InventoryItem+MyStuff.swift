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
            initExisting(json: json)
        } else {
            initNew(json: json)
        }
        
        // Relationship
        self.inventory = inventory
    }

    private func initNew(json: JSON) {

        if let itemID = json["id"].int {
            self.itemID = Int32(itemID)
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let categoryID = json["category_id"].int {
            self.categoryID = Int32(categoryID)
        }
        //if let packSize = json["pack_size"].int {
        //if let inventoryUnitID = json["inventory_unit_id"].int {
        //if let subSize = json["sub_size"].int {
        //if let subUnitID = json["sub_unit_id"].int {
    }
    
    private func initExisting(json: JSON) {

        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let name = json["item"]["name"].string {
            self.name = name
        }
        if let itemID = json["item"]["id"].int {
            self.itemID = Int32(itemID)
        }
        if let categoryID = json["item"]["category"]["id"].int {
            self.categoryID = Int32(categoryID)
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
