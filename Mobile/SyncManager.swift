//
//  SyncManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/4/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

class SyncManager {

    // MARK: - Properties

    private var managedObjectContext: NSManagedObjectContext
    private let completionHandler: ((Bool, Error?) -> Void)
    private let storeID: Int

    // MARK: - Lifecycle

    // We will (1) call some endpoints, (2) sync objects, (3) call completionHandler
    init(storeID: Int, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.storeID = storeID

        // TODO - pass managedObjectContext as init parameter
        //self.managedObjectContext = context
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.completionHandler = completionHandler

        // Get list of Vendors from server
        print("\nFetching Vendors from server ...")
        APIManager.sharedInstance.getVendors(storeID: self.storeID, completion: syncVendors)
    }

    // MARK: - Sync Primary Items
    // TODO - move error handling out into closure of functions calling these methods?

    func syncItems(json: JSON?, error: Error?) {
        guard error == nil else {
            print("\(#function) FAILED : \(error)")
            return completionHandler(false, error)
        }
        guard let json = json else {
            print("\(#function) FAILED : unable to get Items")
            // TODO - construct error?
            return completionHandler(false, nil)
        }

        // Create dict from fetch request on Items
        let prefetch = ["inventoryUnit", "purchaseSubUnit", "purchaseUnit",
                        "subUnit", "vendor"]
        guard let itemDict = try? managedObjectContext.fetchEntityDict(Item.self, prefetchingRelationships: prefetch) else {
            print("\(#function) FAILED : unable to create Item dictionary"); return
        }

        // Create dict from fetch request on Units
        guard let unitDict = try? managedObjectContext.fetchEntityDict(Unit.self) else {
            print("\(#function) FAILED : unable to create Unit dictionary"); return
        }

        let localIDs = Set(itemDict.keys)
        var remoteIDs = Set<Int32>()

        for (_, itemJSON):(String, JSON) in json {
            guard let itemID = itemJSON["id"].int32 else { continue }
            remoteIDs.insert(itemID)

            // Find + update / create Items
            if let existingItem = itemDict[itemID] {
                //print("UPDATE existing Item: \(existingItem)")
                existingItem.update(context: managedObjectContext, withJSON: itemJSON)
                existingItem.updateUnits(withJSON: itemJSON, unitDict: unitDict)

            } else {
                //print("CREATE new Item: \(itemJSON)")
                let newItem = Item(context: managedObjectContext, json: itemJSON)
                newItem.updateUnits(withJSON: itemJSON, unitDict: unitDict)
            }
        }

        // Delete Items that were deleted from server
        let deletedItems = localIDs.subtracting(remoteIDs)

        // TESTING
        print("remote: \(remoteIDs) - local: \(localIDs)")
        print("We need to delete: \(deletedItems)")

        let fetchPredicate = NSPredicate(format: "remoteID IN %@", deletedItems)
        do {
            try managedObjectContext.deleteEntities(Item.self, filter: fetchPredicate)
        } catch {
            // TODO - deleteEntities(_:filter) already prints the error
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        print("Finished syncing Items")
        self.completionHandler(true, nil)
    }

    func syncVendors(json: JSON?, error: Error?) {
        guard error == nil else {
            print("\(#function) FAILED : \(error)")
            return completionHandler(false, error)
        }
        guard let json = json else {
            print("\(#function) FAILED : unable to get Items")
            // TODO - construct error?
            return completionHandler(false, nil)
        }

        do {
            try managedObjectContext.syncEntities(Vendor.self, withJSON: json)
        } catch let error {
            print("\(#function) FAILED : \(error)")
        }
        print("Finished with Vendors")

        // Get list of Items from server
        print("\nFetching Items from server ...")
        APIManager.sharedInstance.getItems(storeID: self.storeID, completion: syncItems)
    }

    // MARK: - Completion
    
    func completedStartup(_ succeeded: Bool) {
        self.completionHandler(true, nil)
    }
    
}
