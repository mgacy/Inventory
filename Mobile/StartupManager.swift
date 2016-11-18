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
    
    //static let sharedInstance = StartupManager()
    
    private var managedObjectContext: NSManagedObjectContext
    private let completionHandler: ((Bool) -> Void)
    private let storeID: Int = 1
    
    // MARK: - Lifecycle
    
    init(completionHandler: @escaping (Bool) -> Void) {
        
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.completionHandler = completionHandler
        
        // 1. Check for existence of email and login.
        if AuthorizationHandler.sharedInstance.userExists {
            print("User exists ...")
            
            // Login to server, then get list of Inventories from server if successful.
            APIManager.sharedInstance.login(completionHandler: self.completedLogin)
        } else {
            print("User does not exist")
            // TODO - how to handle this?
        }
    }

    func completedLogin(_ succeeded: Bool) {
        //print("\nCompleted login - succeeded: \(succeeded)")
        if succeeded {

            // Get list of Items from server
            // print("\nFetching Items from server ...")
            APIManager.sharedInstance.getItems(storeID: self.storeID, completionHandler: completedGetItems)
            
        } else {
            print("Unable to login ...")
        }
    }

    // MARK: - Primary Items
    
    func completedGetItems(success: Bool, json: JSON?) -> Void {
        guard let json = json else {
            print("\nPROBLEM - Unable to get Items"); return
        }
        if success == false {
            print("\nPROBLEM - Unable to get Items"); return
        }
        
        /*
        
        // Get set of ids of response
        let responseIDs = Set(json.arrayValue.map({ $0["id"].intValue }))
        
        // Get set of ids of Items (if they exist)
        let storeIDs: Set<Int>
        let request: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        request.propertiesToFetch = ["remoteID"]
        do {
            let searchResults = try managedObjectContext.fetch(request)

            // Create set of remoteIDs
            storeIDs = Set(searchResults.map { Int(($0 as! Item).remoteID) })

        } catch {
            print("Error with request: \(error)")
            return
        }
        

        // Determine new / deleted items
        let deletedItems = storeIDs.subtracting(responseIDs)
        let newItems = responseIDs.subtracting(storeIDs)
        
        print("Deleted items: \(deletedItems)")
        print("New items: \(newItems)")
 
        // TODO - delete deletedItems
        // 1. perform fetchRequest where remoteID in deletedItems
        // 2. perform batchDelete?
         */
 
        // Create new / update existing Items
        for (_, itemJSON):(String, JSON) in json {
            guard let itemID = itemJSON["id"].int else {
                break
            }
            
            // Find + update / create Items
            if let item = managedObjectContext.fetchWithRemoteID(Item.self, withID: itemID) {
                item.update(context: managedObjectContext, withJSON: itemJSON)
            } else {
                _ = Item(context: managedObjectContext, json: itemJSON)
            }
        }
        
        print("Finished with Items")
        
        self.completionHandler(true)
    }
    
    // func completedGetUnits(success: Bool, json: [JSON]) -> Void { }

    // func completedGetVendors(success: Bool, json: [JSON]) -> Void { }

    // MARK: - Sync
    
    func syncItems(json: JSON) {
        
        // Get set of ids of response
    
        // Get set of ids of Items (if they exist)
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.propertiesToFetch = ["remoteID"]
        // returnsDistinctResults
        
        // Specify we want dictionaries to be returned
        // request.resultType = .dictionaryResultType
    
    }
    
    // MARK: - Completion
    
    func completedStartup(_ succeeded: Bool) {
        self.completionHandler(true)
    }
    
}
