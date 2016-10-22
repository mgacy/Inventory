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
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var destinationController: UIViewController?
    var selectedInventory: Inventory?

    var storeID = 1
    
    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"
    
    // Segues
    // TODO: make enum?
    let ExistingItemSegue = "FetchExistingInventory"
    let SettingsSegue = "ShowSettings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // Get CoreData stuff
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        self.performFetch()
        
        //let xxx = self.fetchedResultsController.fetchedObjects
        //print("Objects: \(xxx)")
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performFetch()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Segues

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case ExistingItemSegue:

            // Get the new view controller.
            guard let controller = segue.destination as? InventoryLocationTVC else {
                print("PROBLEM getting destination controller")
                return
            }

            // Pass selection to new view controller
            if let selection = selectedInventory {
                controller.inventory = selection
                // print("destination.inventory: \(controller.inventory.date)")
                controller.performFetch()
            } else {
                print("PROBLEM getting selection")
            }
            
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell

        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let inventory = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = inventory.date
    }
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    // Override to support editing the table view.
    // override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInventory = self.fetchedResultsController.object(at: indexPath)
        
        print("Selected \(selectedInventory)")

        if let selection = selectedInventory {
            switch selection.uploaded {
            case true:
                guard let locations = selection.locations else {
                    print("PROBLEM: selectedInventory.locations was nil")
                    return
                }
                
                // Check whether we have already fetched Inventory since launching app
                if locations.count > 0 {
                    
                    // LOAD INVENTORY
                    // print("LOAD selectedInventory from disk ...")
                    performSegue(withIdentifier: ExistingItemSegue, sender: self)
                } else {
                    
                    // GET INVENTORY FROM SERVER
                    // print("GET selectedInventory from server ...")
                    let remoteID = Int(selection.remoteID)
                    APIManager.sharedInstance.getInventory(
                        remoteID: remoteID,
                        completionHandler: self.completedGetExistingInventory)
                }
                
            case false:
                // print("LOAD NEW selectedInventory from disk ...")
                performSegue(withIdentifier: ExistingItemSegue, sender: self)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func newTapped(_ sender: AnyObject) {
        // Get new Inventory
        APIManager.sharedInstance.getNewInventory(
            isActive: true, typeID: 1, storeID: storeID, completionHandler: completedGetNewInventory)
    }
    
    // MARK: - Completion Handlers
    
    func completedGetExistingInventory(json: JSON) -> Void {
        if var selection = selectedInventory {

            InventoryHelper.sharedInstance.updateExistingInventory(&selection, withJSON: json)
            
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
            
            performSegue(withIdentifier: ExistingItemSegue, sender: self)
            
        } else {
            print("Still failed to get selected Inventory")
        }
        
    }
    
    func completedGetNewInventory(json: JSON) -> Void {
        
        selectedInventory = InventoryHelper.sharedInstance.createObject(json: json, isNew: true)
        
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
        
        performSegue(withIdentifier: ExistingItemSegue, sender: self)
    }
    
    func completedGetInventories(json: JSON) -> Void {
    
        for (_, item) in json {
            InventoryHelper.sharedInstance.createObject(json: item, isNew: false)
        }
        
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
        let aFetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext!,
            sectionNameKeyPath: nil,
            cacheName: "Master")
        
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        return _fetchedResultsController!
    }
    
    var _fetchedResultsController: NSFetchedResultsController<Inventory>? = nil

    func performFetch () {
        self.fetchedResultsController.managedObjectContext.perform ({
            
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                print("\(#function) FAILED : \(error)")
            }
            self.tableView.reloadData()
        })
    }
    
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
            self.configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

}
