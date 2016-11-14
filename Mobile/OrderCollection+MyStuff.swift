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
    
    convenience init(context: NSManagedObjectContext, date: JSON, uploaded: Bool = false) {
        self.init(context: context)

        // Set properties
        if let _date = date.string {
            self.date = _date
        }
        self.uploaded = uploaded
    }
    
    convenience init(context: NSManagedObjectContext, json: JSON, uploaded: Bool = false) {
        self.init(context: context)
        
        // Set properties
        if let date = json["date"].string {
            self.date = date
        }
        if let inventoryID = json["inventory_id"].int {
            self.inventoryID = Int32(inventoryID)
        }
        if let storeID = json["store_id"].int {
            self.storeID = Int32(storeID)
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
        
        // TODO - handle conversion from NSDate to string
        myDict["date"] = self.date
        
        // ...
        
        return myDict
    }
    
    // MARK: - Update Existing
    
    func updateExisting(context: NSManagedObjectContext, json: JSON) {
        guard let orders = json["orders"].array else {
            print("\nPROBLEM - Unable to get orders from JSON")
            return
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
                print("Found multiple matches: \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
}
