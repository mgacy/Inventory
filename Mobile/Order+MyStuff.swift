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

    convenience init(context: NSManagedObjectContext, json: JSON, collection: OrderCollection) {
        self.init(context: context)

        // Properties
        // if let orderCost = json["order_cost"].float {
        // if let orderDate = json["order_date"].string {

        // For New Order
        // - Relationship
        if let vendorID = json["vendor_id"].int {
            self.fetchVendor(context: context, id: vendorID)
        }
        // - Properties
        if let vendorID = json["vendor_id"].int {
            self.vendorID = Int32(vendorID)
        }
        if let vendorName = json["vendor_name"].string {
            self.vendorName = vendorName
        }
        // if let rep = json["rep"].string { self.
        // if let repEmail = json["rep_email"].string { self.
        // if let repPhone = json["rep_phone"].int { self.
        
        // For Existing Order
        // - Relationship
        if let vendorID = json["vendor"]["id"].int {
            self.fetchVendor(context: context, id: vendorID)
        }
        // - Properties
        if let vendorID = json["vendor"]["id"].int {
            self.vendorID = Int32(vendorID)
        }
        if let vendorName = json["vendor"]["name"].string {
            self.vendorName = vendorName
        }
        /*
        // Rep
        if json["vendor"]["rep"].array != nil {
            // rep = json["vendor"]["rep"]["name"].string {
            // repEmail = json["vendor"]["rep"]["email"].string {
            // repPhone = json["vendor"]["rep"]["phone"].int {
        }
        */
        //}
        
        // Relationships
        self.collection = collection

        // OrderItems
        if let items = json["items"].array {
            print("\nCreating OrderItems ...")
            for itemJSON in items {
                _ = OrderItem(context: context, json: itemJSON, order: self)
            }
        }

    }

    // MARK: - Serialization

    // MARK: - Fetch Object + Establish Relationship
    
    func fetchVendor(context: NSManagedObjectContext, id: Int) {
        let request: NSFetchRequest<Vendor> = Vendor.fetchRequest()
        
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return
            case 1:
                self.vendor = searchResults[0]
            default:
                print("Found multiple matches for unit with id: \(id) - \(searchResults)")
                self.vendor = searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
}
