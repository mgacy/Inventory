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

    enum UnitRelationship {
        case minOrder
        case order
    }
    
    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, order: Order) {
        self.init(context: context)

        // Properties
        if let itemID = json["item"]["id"].int {
            self.itemID = Int32(itemID)
        }
        if let itemName = json["item"]["name"].string {
            self.itemName = itemName
            self.name = itemName
        }
        // TODO - handle category?
        //if let categoryName = json["category"].string {}
        //if let categoryID = json["category_id"].string {}
        
        //if let categoryName = json["item"]["category"]["name"].int {}
        //if let categoryID = json["item"]["category"]["name"].string {}
        
        
        //if let inventory = json["inventory"].string {}

        if let minOrder = json["min_order"].double {
            self.minOrder = minOrder
        }
        if let minOrderUnitID = json["min_order_unit_id"].int {
            fetchUnit(context: context, id: minOrderUnitID, relationship: UnitRelationship.minOrder)
        }
        
        
        if let order = json["order"].double {
            self.quantity = order as NSNumber?
        }
        if let orderUnitID = json["order_unit_id"].int {
            fetchUnit(context: context, id: orderUnitID, relationship: UnitRelationship.order)
        }
        
        if let packSize = json["pack_size"].int {
            self.packSize = Int32(packSize)
        }
        if let par = json["par"].double {
            self.par = par
        }
        
        //if let parUnitID = json["par_unit_id"].int {}
        
        //if let purchaseUnitID = json["purchase_unit_id"].int {}
        //if let purchaseSubUnitID = json["purchase_sub_unit_id"].int {}
        
        // Relationships
        self.order = order
    }

    // MARK: - Serialization

    // MARK: - Fetch Object + Establish Relationship
    
    func fetchItem(context: NSManagedObjectContext, id: Int) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Item with id: \(id)")
                return
            case 1:
                self.item = searchResults[0]
            default:
                print("Found multiple matches for Item with id: \(id) - \(searchResults)")
                self.item = searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    private func fetchUnit(context: NSManagedObjectContext, id: Int, relationship: UnitRelationship) {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")

        do {
            let unit: Unit
            let searchResults = try context.fetch(request)

            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return
            case 1:
                unit = searchResults[0]
            default:
                print("Found multiple matches for Unit with id: \(id) - \(searchResults)")
                unit = searchResults[0]
            }
            
            // Establish relationship
            switch relationship {
            case .minOrder:
                self.minOrderUnit = unit
            case .order:
                self.orderUnit = unit
            }
            
        } catch {
            print("Error with request: \(error)")
        }
    }

}
