//
//  InventoryListTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class InventoryDateTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Properties
    // let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var storeID = 1
    var destinationController: UIViewController?
    
    // NOTE: do I really need this?
    var mySelectedInventory: Inventory?
    
    // TableViewCell
    let CellIdentifier = "InventoryDateTableViewCell"
    
    // Segues
    // TODO: make enum?
    let ExistingItemSegue = "FetchExistingInventory"
    let NewItemSegue = "FetchNewInventory"
    let SettingsSegue = "ShowSettings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        
        // Get CoreData stuff
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // 1. Check for existence of email, login
        if AuthorizationHandler.sharedInstance.userExists {
            print("User exists ...")
            
            // Delete any uploaded Inventories before fetching updated list
            deleteExistingInventories()
            
            // Login to server, then get list of Inventories from server if successful
            APIManager.sharedInstance.login(completionHandler: self.completedLogin)
        } else {
            print("User does not exist")
            // TODO: how to handle this?
        }
        
    }
    
    // override func viewWillAppear(_ animated: Bool) { }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    func insertNewObject(_ sender: Any) {
        print("insertNewObject ...")
        let context = self.fetchedResultsController.managedObjectContext
        
        // GET
        //APIManager.sharedInstance.getNewInventory(isActive: true, typeID: 1, storeID: storeID)
        
        let newInventory = Inventory(context: context)
        
        // If appropriate, configure the new managed object.
        newInventory.date = "New"
        newInventory.uploaded = false
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    */
    
    // MARK: - Segues

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case ExistingItemSegue:
            // Get existing Inventory
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                // Get the new view controller.
                destinationController = segue.destination as! InventoryLocationTVC
                
                let inventory = self.fetchedResultsController.object(at: indexPath)
                //if let remoteID = inventory.remoteID {
                let remoteID = Int(inventory.remoteID)
                APIManager.sharedInstance.getInventory(
                    remoteID: remoteID, completionHandler: self.completedGetExistingInventory)
                //}
            }
        case NewItemSegue:
            // Get the new view controller.
            destinationController = segue.destination as! InventoryLocationTVC
            
            // Get new Inventory
            APIManager.sharedInstance.getNewInventory(
                isActive: true, typeID: 1, storeID: storeID, completionHandler: completedGetNewInventory)
        case SettingsSegue:
            print("Showing Settings ...")
        default:
            break
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as UITableViewCell
        
        // Fetch the appropriate Inventory for the data source layout.
        let inventory = self.fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        self.configureCell(cell, withObject: inventory)

        return cell
    }
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    // Override to support editing the table view.
    // override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}

    func configureCell(_ cell: UITableViewCell, withObject object: Inventory) {
        cell.textLabel?.text = object.date
    }
    
    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedInventory = self.fetchedResultsController.object(at: indexPath)
        
        print("Selected \(selectedInventory)")
        mySelectedInventory = selectedInventory
        
        // Perform segue based on .uploaded of selected Inventory
        switch selectedInventory.uploaded {
        case true:
            performSegue(withIdentifier: ExistingItemSegue, sender: self)
        case false:
            print("We need to load this item from disk ...")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Completion Handlers
    
    func completedGetExistingInventory(json: JSON) -> Void {
        print("completedGetExistingInventory ...")
        //print("completedGetExistingInventory: \(json)")

        if var sel = mySelectedInventory {

            print("We need to update \(sel)")
            InventoryHelper.sharedInstance.updateExistingInventory(&sel, withJSON: json)
            print("Updated Inventory: \(sel)")
            
            // Save the context.
            let context = self.fetchedResultsController.managedObjectContext
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            // Set properties of next controller
            if let controller = destinationController as? InventoryLocationTVC {
                controller.inventory = sel
                //controller.managedObjectContext = managedObjectContext
                //controller.locations = inventory.locations
                controller.tableView.reloadData()
            }
            
        } else {
            print("Still failed to get selected Inventory")
        }
        
    }
    
    func completedGetNewInventory(json: JSON) -> Void {
        let context = self.fetchedResultsController.managedObjectContext
        
        print("completedGetNewInventory ...")
        //print("completedGetNewInventory: \(json)")
        
    
        let newInventory = Inventory(context: context)
        
        // If appropriate, configure the new managed object.
        newInventory.date = "New"
        newInventory.uploaded = false
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        /*
        // Set properties of next controller
        if let controller = destinationController as? InventoryLocationTVC {
            controller.inventory = inventory
            controller.locations = inventory.locations
            controller.tableView.reloadData()
        }
        */

    }
    
    func completedGetInventories(json: JSON) -> Void {
        print("completedGetInventories ...")
        //print("completedGetInventories: \(json)")
        
        let context = self.fetchedResultsController.managedObjectContext
    
        print("Creating Inventories ...")
        for (_, item) in json {
            print("item: \(item)")
            let newInventory = Inventory(context: context)
            
            // Properties
            newInventory.date = item["date"].string
            
            if let remoteID = item["id"].int {
                newInventory.remoteID = Int32(remoteID)
            }
            // store_id
            // inventory_type_id
            newInventory.uploaded = true
            
        }
        
        print("Saving context ...")
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

    }
    
    func completedLogin(_ succeeded: Bool) {
        if succeeded {
            print("\nCompleted login - succeeded: \(succeeded)")
            
            // Get list of Inventories from server
            print("\nFetching existing Inventories from server ...")
            APIManager.sharedInstance.getInventories(storeID: storeID, completionHandler: self.completedGetInventories)
            
        } else {
            print("Unable to login ...")
        }
    }
    
    // MARK: - A
    
    func deleteExistingInventories() {
        print("deleteExistingInventories ...")
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        
        // Configure Fetch Request
        //let uploaded = true
        //let uploaded = nil
        //fetchRequest.predicate = NSPredicate(format: "uploaded == \(uploaded)")
        fetchRequest.predicate = NSPredicate(format: "uploaded == true")
        
        // Initialize Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount
        
        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext?.execute(batchDeleteRequest) as! NSBatchDeleteResult
            
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
            
            // Reset Managed Object Context
            managedObjectContext?.reset()
            
            // Perform Fetch
            try self.fetchedResultsController.performFetch()
            
            // Reload Table View
            tableView.reloadData()
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
        
        
        
        
        /*
        var results: [NSManagedObject] = []
        
        do {
            results = try managedObjectContext!.fetch(fetchRequest)
            print("Found matches: \(results)")
            managedObjectContext?.deletedObjects
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        */
        print("/ deleteExistingInventories")
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Inventory> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        //let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Inventory>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, withObject: anObject as! Inventory)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
}
