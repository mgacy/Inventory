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
    
    var destinationController: UIViewController?
    var selectedInventory: Inventory?
    
    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    //var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit
    
    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"
    
    // Segues
    // TODO - make enum?
    let ExistingItemSegue = "FetchExistingInventory"
    let SettingsSegue = "ShowSettings"

    // TODO - provide interface to control this
    var storeID = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        title = "Inventories"
        
        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()
        
        // 1. Check for existence of email and login.
        if AuthorizationHandler.sharedInstance.userExists {
            print("User exists ...")
            
            // Delete any uploaded Inventories before fetching updated list.
            deleteExistingInventories(NSPredicate(format: "uploaded == true"))
            
            // Login to server, then get list of Inventories from server if successful.
            APIManager.sharedInstance.login(completionHandler: self.completedLogin)
        } else {
            print("User does not exist")
            // TODO - how to handle this?
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
                print("\nPROBLEM - Unable to get destination controller\n")
                return
            }

            // Pass selection to new view controller.
            if let selection = selectedInventory {
                controller.inventory = selection
                controller.managedObjectContext = self.managedObjectContext
                //controller.performFetch()
            } else {
                print("\nPROBLEM - Unable to get selection\n")
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
        
        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.blueColor
        }
    }
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    // Override to support editing the table view.
    // override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInventory = self.fetchedResultsController.object(at: indexPath)
        if let selection = selectedInventory {
            switch selection.uploaded {
            case true:
                guard let locations = selection.locations else {
                    print("\nPROBLEM - selectedInventory.locations was nil\n")
                    return
                }
                
                // Check whether we have already fetched Inventory since launching app.
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
        // Get new Inventory.
        APIManager.sharedInstance.getNewInventory(
            isActive: true, typeID: 1, storeID: storeID, completionHandler: completedGetNewInventory)
    }
    
    @IBAction func resetTapped(_ sender: AnyObject) {
        // By leaving filter as nil, we will delete all Inventories
        deleteExistingInventories()
        // Download Inventories from server again
        completedLogin(true)
    }
    
    // MARK: - Completion Handlers
    
    func completedGetExistingInventory(json: JSON) -> Void {
        if let selection = selectedInventory {

            // Update selected Inventory with full JSON from server.
            selection.updateExisting(context: self.managedObjectContext!, json: json)
            
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
            print("\nPROBLEM - Still failed to get selected Inventory\n")
        }
        
    }
    
    func completedGetNewInventory(json: JSON) -> Void {
        selectedInventory = Inventory(context: self.managedObjectContext!, json: json, uploaded: false)
        
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
            _ = Inventory(context: self.managedObjectContext!, json: item, uploaded: true)
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
            // print("\nFetching existing Inventories from server ...")
            APIManager.sharedInstance.getInventories(storeID: storeID, completionHandler: self.completedGetInventories)
            
        } else {
            print("Unable to login ...")
        }
    }
    
    // MARK: - A
    
    func deleteExistingInventories(_ filter: NSPredicate? = nil) {
        print("deleteExistingInventories ...")
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        
        // Configure Fetch Request
        if let _filter = filter { fetchRequest.predicate = _filter }
        
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
            sectionNameKeyPath: self.sectionNameKeyPath,
            cacheName: self.cacheName)
        
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
