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
        
        if let itemID = json["item"]["id"].int {
            self.itemID = Int32(itemID)
        }
        //if let itemName = json["item"]["name"].string {
        //    self.itemName = itemName
        //    self.name = itemName
        //}
        
        if let onHand = json["inventory"].double {
            self.onHand = onHand //as NSNumber?
        }
        
        // par
        if let par = json["par"].double {
            self.par = par
        }
        if let parUnitID = json["par_unit_id"].int {
            self.parUnit = self.fetchEntityByID(entityType: Unit.self, context: context, id: parUnitID)
        }
        
        // minOrder
        if let minOrder = json["min_order"].double {
            self.minOrder = minOrder
            self.quantity = minOrder as NSNumber?
        }
        if let minOrderUnitID = json["min_order_unit_id"].int {
            self.minOrderUnit = self.fetchEntityByID(entityType: Unit.self, context: context, id: minOrderUnitID)
        }
        
        // order
        if let order = json["order"].double {
            self.quantity = order as NSNumber?
        }
        if let orderUnitID = json["order_unit_id"].int {
            self.orderUnit = self.fetchEntityByID(entityType: Unit.self, context: context, id: orderUnitID)
        }
        
        // Relationships
        
        if let itemID = json["item"]["id"].int {
            //print("Searching for Item with \(itemID)")
            if let item = Item.withID(itemID, fromContext: context) {
                //print("Found Item: \(item)")
                self.item = item
            }
        }
        
        self.order = order
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        
        myDict["item_id"] = self.item?.remoteID
        myDict["order_quant"] = self.quantity
        myDict["order_unit_id"] = self.orderUnit?.remoteID
        
        return myDict
    }
    
    // MARK: - Fetch Entity
    
    func fetchEntityByID<T: NSManagedObject>(entityType: T.Type, context moc: NSManagedObjectContext, id: Int) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try moc.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find entity with id: \(id)")
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches: \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
}
