//
//  InventoryHelper.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/19/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

public class InventoryHelper {
    
    public static let sharedInstance = InventoryHelper()
    
    var context: NSManagedObjectContext
    //var context: NSManagedObjectContext? = nil
    // var object: NSManagedObject?
    
    // MARK: - Lifecycle
    
    public init() {
        self.context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    /*
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    */
    
    @discardableResult
    public func createObject(json: JSON, isNew: Bool = true) -> Inventory {
        print("Creating object ...")
        
        // Create entity
        var inventory = Inventory(context: context)
        
        // Set properties
        inventory.date = json["date"].string
        if let remoteID = json["id"].int {
            inventory.remoteID = Int32(remoteID)
        }
        if let storeID = json["store_id"].int {
             inventory.storeID = Int32(storeID)
        }
        if let typeID = json["inventory_type_id"].int {
             inventory.typeID = Int32(typeID)
        }
        if isNew {
            inventory.uploaded = false
        } else {
            inventory.uploaded = true
        }
        
        // Add InventoryItems
        if let items = json["items"].array {
            // Currently, JSON will include "items" only for new Inventories
            if isNew {
                addItemsForNew(&inventory, json: items)
            }
        }

        // Add InventoryLocations
        if let locations = json["locations"].array {
            addLocations(&inventory, json: locations)
        }
        
        // Save
        //print("Entity: \(inventory)")
        //context.saveContext()
        
        return inventory
    }

    // MARK: - New
    
    func addItemsForNew(_ inventory: inout Inventory, json: [JSON]) {
        for object in json {
            let item = InventoryItem(context: context)
            
            // Properties
            if let itemID = object["id"].int {
                item.itemID = Int32(itemID)
            }
            if let name = object["name"].string {
                item.name = name
            }
            if let categoryID = object["category_id"].int {
                item.categoryID = Int32(categoryID)
            }
            //if let packSize = item["pack_size"].int {
            //if let inventoryUnitID = object["inventory_unit_id"].int {
            //if let subSize = object["sub_size"].int {
            //if let subUnitID = object["sub_unit_id"].int {
            
            // Relationship
            item.inventory = inventory
        }
    }

    func addLocations(_ inventory: inout Inventory, json: [JSON]) {
        for object in json {
            var location = InventoryLocation(context: context)

            // Properties
            if let name = object["name"].string {
                location.name = name
            }
            if let remoteID = object["id"].int {
                location.remoteID = Int32(remoteID)
            }
            if let locationType = object["loc_type"].string {
                location.locationType = locationType
            }

            // Relationship
            location.inventory = inventory

            // X based on Location type
            switch location.locationType {
            case "item"?:
                if let itemIDs = object["items"].array {
                    addLocationItems(location: &location, json: itemIDs)
                }
            case "category"?:
                print("Type: category")
                if let categories = object["categories"].array {
                    addCategoriesToNew(location: &location, json: categories)
                }
            default:
                print("Type: other")
            }
            
            print("Adding InventoryLocation: \(location)")
        }
    }
    
    /// Describe me
    ///
    /// - parameter parent:     Either InventoryLocation or InventoryLocationCategory
    /// - parameter parentType: Either "location" or "category"
    /// - parameter json:       JSON
    func addLocationItems(location: inout InventoryLocation, json: [JSON]) {
        for (position, itemID) in json.enumerated() {
            if let itemID = itemID.int {
                let locItem = addLocationItem(itemID: itemID, position: position + 1)
                locItem.location = location
            }
        }
    }

    func addLocationItems(category: inout InventoryLocationCategory, json: [JSON]) {
        // We want alphabetical sorting of Items for LocationCategories, so omit position
        for itemID in json {
            if let itemID = itemID.int {
                let locItem = addLocationItem(itemID: itemID, position: nil)
                locItem.category = category
            }
        }
    }
    
    func addLocationItem(itemID: Int, position: Int?) -> InventoryLocationItem {
        let locItem = InventoryLocationItem(context: self.context)
        
        // Set properties
        locItem.itemID = Int32(itemID)
        if let position = position {
            locItem.position = Int16(position)
        }
    
        // Try to find corresponding item and add relationship
        if let item = fetchInventoryItem(itemID: itemID) {
            // print("Found Item: \(item)")
            locItem.item = item
        }
    
        return locItem
    }
    
    func addCategoriesToNew(location: inout InventoryLocation, json: [JSON]) {
        for object in json {
            var category = InventoryLocationCategory(context: self.context)
            
            // Properties
            if let name = object["name"].string {
                category.name = name
            }
            if let categoryID = object["id"].int {
                category.categoryID = Int32(categoryID)
            }
            
            // Relationship
            category.location = location
            
            // LocationItems
            if let itemIDs = object["items"].array {
                addLocationItems(category: &category, json: itemIDs)
            }
        }
    }
    
    // MARK: - Existing
    
    func updateExistingInventory(_ inventory: inout Inventory, withJSON json: JSON) {

        // Add Default Location
        var defaultLocation = InventoryLocation(context: self.context)
        defaultLocation.name = "Default"
        defaultLocation.remoteID = 1
        defaultLocation.inventory = inventory
        defaultLocation.locationType = "category"
        
        // Iterate over items
        if let inventoryItems = json["items"].array {
            for inventoryItem in inventoryItems {
                
                // Create InventoryItem
                var newItem = InventoryItem(context: self.context)
                
                if let remoteID = inventoryItem["id"].int {
                    newItem.remoteID = Int32(remoteID)
                }
                if let itemID = inventoryItem["item"]["id"].int {
                    newItem.itemID = Int32(itemID)
                }
                if let name = inventoryItem["item"]["name"].string {
                    newItem.name = name
                }
                
                // Create InventoryLocationItem
                var newLocItem = InventoryLocationItem(context: self.context)
                
                if let quantity = inventoryItem["quantity"].double {
                    newLocItem.quantity = quantity as NSNumber?
                }
                
                // Get corresponding Unit
                if let unitID = inventoryItem["unit_id"].int {
                    if let inventoryUnit = fetchUnit(id: unitID) {
                        newLocItem.unit = inventoryUnit
                    }
                }
                
                // Fetch / Create corresponding InventoryLocationCategory and create relationships
                addCategoryToExisting(location: &defaultLocation, item: &newItem, locItem: &newLocItem,
                                      json: inventoryItem)

                // Add InventoryItem to Inventory
                newItem.inventory = inventory
                
                // Add InventoryLocationItem to InventoryItem
                newLocItem.item = newItem
                
                // Add InventoryLocationItem to Location
                newLocItem.location = defaultLocation
            }
        }
    }

    // ME: isn't this covered by updateExistingInventory()?
    func addItemsForExisting(_ inventory: inout Inventory, json: [JSON]) {
        for object in json {
            let item = InventoryItem(context: context)
            
            // Properties
            if let remoteID = object["id"].int {
                item.remoteID = Int32(remoteID)
            }
            if let name = object["item"]["name"].string {
                item.name = name
            }
            if let itemID = object["item"]["id"].int {
                //if let itemID = object["item_id"].int {
                item.itemID = Int32(itemID)
            }
            if let categoryID = object["item"]["category"]["id"].int {
                item.categoryID = Int32(categoryID)
            }
            
            //if let quantity = object["quantity"].double {
            //    item.quantity = Int32(quantity)
            //}
            // if let unitID = object["unit_id"].int {
            
            // Relationship
            item.inventory = inventory
        }
    }
    
    /// For existing Inventory; ...
    ///
    /// - parameter location: InventoryLocation
    /// - parameter item:     InventoryItem
    /// - parameter locItem:  InventoryLocationItem
    /// - parameter json:     Relevant JSON
    func addCategoryToExisting(location: inout InventoryLocation, item: inout InventoryItem,
                               locItem: inout InventoryLocationItem, json: JSON) {
        
        // Handle ItemCategory and InventoryLocationCategory
        guard let categoryName = json["item"]["category"]["name"].string else { return }
        guard let id = json["item"]["category"]["id"].int else { return }
        let categoryID = Int32(id)
        
        // TODO: fetch / add corresponding ItemCategory?
        item.categoryID = categoryID
        
        var theLocCat: InventoryLocationCategory
        if let theLocCat = location.categories?.filter({ ($0 as! InventoryLocationCategory).categoryID == categoryID }).first {
            
            // Found InventoryLocationCategory
            (theLocCat as! InventoryLocationCategory).location = location
            locItem.category = (theLocCat as! InventoryLocationCategory)
            
        } else {
            
            // Create new InventoryLocationCategory
            theLocCat = InventoryLocationCategory(context: self.context)
            theLocCat.name = categoryName
            theLocCat.categoryID = categoryID
            
            theLocCat.location = location
            locItem.category = theLocCat
        }
    }
    
    // func addItemsToDefaultLocation() {}
    
    // MARK: - Fetch Items
    /*
    class func objectsForEntity(entityName:String, context:NSManagedObjectContext,
                                filter:NSPredicate?, sort:[NSSortDescriptor]?) -> [AnyObject]? {
        let request = NSFetchRequest(entityName:entityName)
        request.predicate = filter
        request.sortDescriptors = sort
        do {
            return try context.executeFetchRequest(request)
        } catch {
            print("\(#function) FAILED to fetch objects for \(entityName) entity")
            return nil
        }
    }
    */
    
    func fetchUnit(id: Int) -> Unit? {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches for unit with id: \(id) - \(searchResults)")
                return searchResults[0]
            }

        } catch {
            print("Error with request: \(error)")
        }
        
        return nil
    }
    
    func fetchInventoryItem(itemID: Int) -> InventoryItem? {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        
        request.predicate = NSPredicate(format: "itemID == \(Int32(itemID))")
        
        do {
            let searchResults = try context.fetch(request)
            if searchResults.count == 1 {
                return searchResults[0]
            } else {
                print("Found multiple matches: \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
}

