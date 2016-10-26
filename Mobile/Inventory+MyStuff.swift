//
//  Inventory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension Inventory {
    
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, json: JSON, uploaded: Bool = true) {
        self.init(context: context)
    
        // Set properties
        if let date = json["date"].string {
            self.date = date
        }
        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let storeID = json["store_id"].int {
            self.storeID = Int32(storeID)
        }
        if let typeID = json["inventory_type_id"].int {
            self.typeID = Int32(typeID)
        }
        self.uploaded = uploaded

        // Add InventoryItems
        if let items = json["items"].array {
            // Currently, JSON will include "items" only for new Inventories
            for itemJSON in items {
                _ = InventoryItem(context: context, json: itemJSON, inventory: self)
            }
        }

        // Add InventoryLocations
        if let locations = json["locations"].array {
            for locationJSON in locations {
                _ = InventoryLocation(context: context, json: locationJSON, inventory: self)
            }
        }
    }
    
    // MARK: - Update Existing
    
    func updateExisting(context: NSManagedObjectContext, json: JSON) {
    
        // Add Default Location
        //let defaultLocation = InventoryLocation(context: context)
        let defaultLocation = InventoryLocation(context: context, name: "Default", remoteID: 1,
                                                type: InventoryLocationType.category, inventory: self)
        
        // Iterate over Items
        if let inventoryItems = json["items"].array {
            print("Updating ...")
            for inventoryItemJSON in inventoryItems {
            
                // Create InventoryItem
                let inventoryItem = InventoryItem(context: context, json: inventoryItemJSON,
                                                  inventory: self)
                print("Created InventoryItem: \(inventoryItem)")
                
                // Create InventoryLocationItem
                let locationItem = InventoryLocationItem(context: context)
                if let quantity = inventoryItemJSON["quantity"].double {
                    locationItem.quantity = quantity as NSNumber?
                }
                locationItem.item = inventoryItem
                // TODO - am I still setting location when a LocationItem belongs to a LocationCategory?
                locationItem.location = defaultLocation

                //print("Created InventoryLocationItem: \(locationItem)")
                
                /*
                // Get Corresponding Unit
                if let unitID = inventoryItemJSON["unit_id"].int {
                    locationItem.fetchUnit(context: context, id: unitID)
                    //if let inventoryUnit = fetchUnit(id: unitID) {
                    //    locationItem.unit = inventoryUnit
                    //}
                }
                */
                
                // Fetch / Create corresponding InventoryLocationCategory and create relationships
                defaultLocation.doStuff(context: context, json: inventoryItemJSON,
                                        location: defaultLocation,
                                        locationItem: locationItem)
                
                print("Created InventoryLocationItem: \(locationItem)")
                
            }
        }
    
        print("Created InventoryLocation: \(defaultLocation)")
    }
    
    private func addItemsToExisting() {
        
    }

}