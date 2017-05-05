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

    public func createObject(json: JSON, isNew: Bool = true) -> Inventory {
        log.verbose("Creating object ...")

        // Create entity
        let inventory = Inventory(context: context)

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
            inventory.uploaded = true
        } else {
            inventory.uploaded = false
        }

        // Add InventoryItems
        /*
        if let items = json["items"].array {
            for item in items {
                
            }
            
            let itemEntities = addItems(json: items)
            for item in itemEntities {
                item.setValue(inventory, forKey: "inventory")
            }
        }
        */
        // Add InventoryLocations
        if let locations = json["locations"].array {
            for loc in locations {
                let location = addLocation(json: loc)
                location.inventory = inventory
                //location.setValue(inventory, forKey: "inventory")
                //log.verbose("Adding InventoryLocation: \(location)")
            }
        }

        // Save
        log.verbose("Entity: \(inventory)")
        //context.saveContext()

        //return inventory as! Inventory
        return inventory
    }

    // MARK: - A

    func addItemForExisting(json: JSON) -> InventoryItem {
        let item = InventoryItem(context: context)
        return item
    }

    func addItemForNew(json: JSON) -> InventoryItem {
        let item = InventoryItem(context: context)
        return item
    }

    func addLocation(json: JSON) -> InventoryLocation {
        let location = InventoryLocation(context: context)
        return location
    }

    // MARK: - B

    func addLocations(inventory: inout Inventory, json: [JSON]) {
        for object in json {
            let location = InventoryLocation(context: context)

            if let name = object["name"].string {
                location.name = name
            }
            if let remoteID = object["id"].int {
                location.remoteID = Int32(remoteID)
            }
            if let locationType = object["loc_type"].string {
                location.locationType = locationType
            }
            location.inventory = inventory

            // X based on Location type
            switch location.locationType {
            case "item"?:
                //if let itemIDs = object["items"].array {
                print("Type: item")
            case "category"?:
                log.verbose("Type: category")
            default:
                log.verbose("Type: other")
            }

            //log.verbose("Adding InventoryLocation: \(location)")
        }
    }

    /// Describe me
    ///
    /// - parameter parent:     Either InventoryLocation or InventoryLocationCategory
    /// - parameter parentType: Either "location" or "category"
    /// - parameter json:       JSON
    func addLocationItems(parent: inout AnyObject, parentType: String, json: JSON) {

        switch parentType {
        case "location":
            print("location")
            // InventoryLocationItem.location = parent
        case "category":
            print("category")
            // InventoryLocationItem.category = parent
        default:
            print("other")
        }

    }

    // MARK: - C

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

                // Create InventoryLocationItem
                var newLocItem = InventoryLocationItem(context: self.context)

                if let quantity = inventoryItem["quantity"].double {
                    newLocItem.quantity = quantity
                }
                /*
                if let unitID = inventoryItem["unit_id"].int {
                    // Get corresponding Unit
                    if let inventoryUnit = fetchUnit(id: unitID) {
                        newLocItem.unit = inventoryUnit
                    }
                }
                */
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

    func addItemsToDefaultLocation() {

    }

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
        //let fetchRequest = NSFetchRequest<Unit>
        let fetchRequest: NSFetchRequest<Unit> = Unit.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteID == \(id)")

        var results: [Unit] = []

        do {
            // return try self.context.executeFetchRequest(request)
            results = try self.context.fetch(fetchRequest)
            if results.count == 1 {
                return results[0]
            } else {
                print("Found multiple matches: \(results)")
                //return nil
            }

        } catch {
            print("error executing fetch request: \(error)")
        }

        return nil
    }

    // MARK: - C

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

        /// TODO: fetch / add corresponding ItemCategory?
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

}
