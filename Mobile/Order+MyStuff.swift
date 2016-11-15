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

extension Order {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, collection: OrderCollection, uploaded: Bool = false) {
        self.init(context: context)

        // Properties
        // if let orderCost = json["order_cost"].float {}
        // if let orderDate = json["order_date"].string {}
        self.placed = uploaded
        self.uploaded = uploaded

        // Relationships
        self.collection = collection
        if let vendorID = json["vendor"]["id"].int {
            self.vendor = self.fetchVendor(context: context, id: vendorID)
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
            print("\nCreating OrderItems ...")
            for itemJSON in items {
                _ = OrderItem(context: context, json: itemJSON, order: self)
            }
        }
    }

    // MARK: - Serialization

    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        
        // TODO - handle conversion from NSDate to string
        myDict["order_date"] = self.collection?.date
        myDict["vendor_id"] = self.vendor?.remoteID
        
        // TODO - remove hard-coded values
        myDict["store_id"] = 1
        
        // Generate array of dictionaries for InventoryItems
        guard let items = self.items else {
            print("\nPROBLEM - Unable to serialize without any OrderItems")
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
    
    func getOrderMessage() -> String? {
        guard let items = self.items else { return nil }

        var messageItems: [String] = []
        for case let item as OrderItem in items {
            guard let quantity = item.quantity else { return nil }
            
            if Int(quantity) > 0 {
                guard let name = item.item?.name else { break }
                messageItems.append("\n\(name) \(quantity) \(item.orderUnit?.abbreviation ?? "")")
            }
        }

        if messageItems.count == 0 { return nil }
        
        messageItems.sort()
        let message = "Order for \(self.collection?.date ?? ""):\n\(messageItems.joined(separator: ""))"

        return message
    }
    
    // MARK: - Fetch Object + Establish Relationship
    
    func fetchVendor(context: NSManagedObjectContext, id: Int) -> Vendor? {
        let request: NSFetchRequest<Vendor> = Vendor.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Vendor with id: \(id)")
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches for Vendor with id: \(id) - \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
}
