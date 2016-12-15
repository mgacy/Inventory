//
//  StartupManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/4/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

class StartupManager {

    // MARK: - Properties

    private var managedObjectContext: NSManagedObjectContext
    private let completionHandler: ((Bool) -> Void)
    private let storeID: Int = 1

    // MARK: - Lifecycle

    // We will (1) call some endpoints, (2) sync objects, (3) call completionHandler
    init(completionHandler: @escaping (Bool) -> Void) {
        
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.completionHandler = completionHandler

        // Get list of Vendors from server
        print("\nFetching Vendors from server ...")
        APIManager.sharedInstance.getVendors(storeID: self.storeID, completion: completedGetVendors)
    }

    // MARK: - Primary Items

    func completedGetItems(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            print("\(#function) FAILED : \(error)"); return
        }
        guard let json = json else {
            print("\(#function) FAILED : unable to get Items"); return
        }

        // Set up fetch request
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()

        // Relationships we'll touch:
        fetchRequest.relationshipKeyPathsForPrefetching = [
            "inventoryUnit", "purchaseSubUnit", "purchaseUnit",
            "subUnit", "vendor"
        ]

        // Relationships we won't:
        // inventoryItems, invoiceItems, orderItems

        do {
            let searchResults = try managedObjectContext.fetch(fetchRequest)
            syncItems(searchResults: searchResults as! [Item], json: json)

        } catch {
            print("Error with request: \(error)")
            return
        }
    }

    // func completedGetUnits(success: Bool, json: [JSON]) -> Void { }

    func completedGetVendors(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            print("\(#function) FAILED : \(error)"); return
        }
        guard let json = json else {
            print("\(#function) FAILED : unable to get Items"); return
        }

        // Create new / update existing Vendors
        for (_, vendorJSON):(String, JSON) in json {
            guard let vendorID = vendorJSON["id"].int else {
                break
            }

            // Find + update / create Vendors
            if let vendor = managedObjectContext.fetchWithRemoteID(Vendor.self, withID: vendorID) {
                vendor.update(context: managedObjectContext, withJSON: vendorJSON)
            } else {
                _ = Vendor(context: managedObjectContext, json: vendorJSON)
            }
        }

        print("Finished with Vendors")

        // Get list of Items from server
        print("\nFetching Items from server ...")
        APIManager.sharedInstance.getItems(storeID: self.storeID, completion: completedGetItems)
    }

    // MARK: - Sync

    func syncItems(searchResults: [Item], json: JSON) {

        // Create dict from array of Items returned from fetch request
        let dictionary = searchResults.toDictionary { $0.remoteID }

        for (_, itemJSON):(String, JSON) in json {
            guard let itemID = itemJSON["id"].int else {
                break
            }
            let id = Int32(itemID)

            // Find + update / create Items
            if let existingItem = dictionary[id] {
                //print("UPDATE existing item \(existingItem)")
                existingItem.update(context: managedObjectContext, withJSON: itemJSON)

            } else {
                //print("CREATE new item \(itemJSON)")
                _ = Item(context: managedObjectContext, json: itemJSON)
            }
        }

        // TODO - delete Items that were deleted from server
        /*
        // Get set of ids of response
        let responseIDs = Set(json.arrayValue.map({ Int32($0["id"].intValue) }))
        let storeIDs = Set(dictionary.keys)

        // Determine new / deleted items
        let deletedItems = storeIDs.subtracting(responseIDs)
        let newItems = responseIDs.subtracting(storeIDs)

        print("Deleted items: \(deletedItems)")
        print("New items: \(newItems)")

        // TODO - delete deletedItems
        // 1. perform fetchRequest where remoteID in deletedItems
        // 2. perform batchDelete?
        */

        print("Finished syncing Items")
        self.completionHandler(true)
    }

    /*
    func syncVendors(searchResults: [Vendor], json: JSON) {

        // Create dict from array of Vendors returned from fetch request
        let dictionary = searchResults.toDictionary { $0.remoteID }

        for (_, vendorJSON):(String, JSON) in json {
            guard let vendorID = vendorJSON["id"].int else {
                break
            }
            let id = Int32(vendorID)

            // Find + update / create Vendors
            if let existingVendor = dictionary[id] {
                //print("UPDATE existing Vendor \(existingVendor)")
                existingVendor.update(context: managedObjectContext, withJSON: vendorJSON)

            } else {
                //print("CREATE new Vendor \(vendorJSON)")
                _ = Vendor(context: managedObjectContext, json: vendorJSON)
            }
        }

        // TODO - delete Vendors that were deleted from server

        print("Finished with Vendors")

        // Get list of Items from server
        print("\nFetching Items from server ...")
        APIManager.sharedInstance.getItems(storeID: self.storeID, completion: completedGetItems)
    }
    */

    // MARK: - Completion
    
    func completedStartup(_ succeeded: Bool) {
        self.completionHandler(true)
    }
    
}
