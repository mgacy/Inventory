//
//  OrderDateTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class OrderDateTVC: UITableViewController, NSFetchedResultsControllerDelegate {

    // MARK: Properties
    
    var selectedCollection: OrderCollection?
    
    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit
    
    // TableViewCell
    let cellIdentifier = "Cell"
    
    // Segues
    let segueIdentifier = "showOrderVendors"
    
    // TODO - provide interface to control these
    var storeID = 1
    let orderTypeID = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        title = "Orders"
        
        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()
        
        // 1. Check for existence of email and login.
        if AuthorizationHandler.sharedInstance.userExists {
            print("User exists ...")
            
            // Delete any uploaded Inventories before fetching updated list.
            //deleteExistingOrders(NSPredicate(format: "completed == true"))
            deleteExistingOrders()
            
            // Login to server, then get list of Inventories from server if successful.
            APIManager.sharedInstance.login(completionHandler: self.completedLogin)
        } else {
            print("User does not exist")
            // TODO - how to handle this?
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.performFetch()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let collection = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = collection.date
        
        switch collection.completed {
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
        selectedCollection = self.fetchedResultsController.object(at: indexPath)
        guard let selection = selectedCollection else { return }
        
        switch selection.completed {
        case true:
            guard let orders = selection.orders else {
                print("\nPROBLEM - selectedCollection.orders was nil\n")
                return
            }
            
            // Check whether we have already fetched Collection since launch.
            if orders.count > 0 {
                // LOAD
                performSegue(withIdentifier: segueIdentifier, sender: self)
            } else {
                // GET
                print("GET OrderCollection from server ...")
                guard let collectionDate = selection.date else {
                    print("\nPROBLEM - Unable to get orderCollection.date")
                    return
                }
                APIManager.sharedInstance.getOrder(
                    storeID: storeID, orderDate: collectionDate,
                    completionHandler: completedGetExistingOrderCollection)
            }
            
        case false:
            print("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        // Get the new view controller.
        guard let controller = segue.destination as? OrderVendorTVC else {
            print("\nPROBLEM - Unable to get destination controller\n")
            return
        }
        
        // Pass selection to new view controller.
        if let selection = selectedCollection {
            controller.parentObject = selection
            controller.managedObjectContext = self.managedObjectContext
            //controller.performFetch()
        } else {
            print("\nPROBLEM - Unable to get selection\n")
        }
    }

    @IBAction func newTapped(_ sender: AnyObject) {
        // Get new OrderCollection.
        APIManager.sharedInstance.getNewOrder(
            storeID: storeID, typeID: orderTypeID, returnUsage: true,
            periodLength: 28, completionHandler: completedGetNewOrderCollection)
    }
    
    // MARK: - Completion Handlers
    
    func completedInit(json: JSON) -> Void {
        
    }
    
    func completedGetListOfOrderCollections(json: JSON) -> Void {
        guard let dates = json["dates"].array else {
            print("\nPROBLEM - Failed to get dates")
            return
        }
        
        for date in dates {
            _ = OrderCollection(context: self.managedObjectContext!, date: date, completed: true)
        }
    
        // Save the context.
        saveContext()
    }
    
    func completedGetExistingOrderCollection(json: JSON) -> Void {
        guard let selection = selectedCollection else {
            print("\nPROBLEM - Still failed to get selected OrderCollection\n")
            return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)
        
        // Save the context.
        saveContext()
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewOrderCollection(json: JSON) -> Void {
        print("\nCreating new OrderCollection ...")
        selectedCollection = OrderCollection(context: self.managedObjectContext!, json: json, completed: false)
        
        // Save the context.
        saveContext()
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    func completedLogin(_ succeeded: Bool) {
        if succeeded {
            print("\nCompleted login - succeeded: \(succeeded)")
            
            // Get list of OrderCollections from server
            // print("\nFetching existing OrderCollections from server ...")
            APIManager.sharedInstance.getListOfOrders(storeID: storeID, completionHandler: self.completedGetListOfOrderCollections)
            
        } else {
            print("Unable to login ...")
        }
    }
    
    // MARK: - A
    
    func saveContext() {
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
    
    func deleteExistingOrders(_ filter: NSPredicate? = nil) {
        print("deleteExistingOrders...")
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        
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
    
    var fetchedResultsController: NSFetchedResultsController<OrderCollection> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = fetchBatchSize
        
        // Edit the sort key as appropriate.
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
    
    var _fetchedResultsController: NSFetchedResultsController<OrderCollection>? = nil
    
    func performFetch () {
        self.fetchedResultsController.managedObjectContext.perform ({
            
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                print("\(#function) FAILED : \(error)")
            }
            
            // TESTING:
            let objects = self.fetchedResultsController.fetchedObjects
            print("Fetched Objects: \(objects?.count)")
            if let expectedObjects = self.fetchedResultsController.fetchedObjects {
                print("OrderDateTVC should display: \(expectedObjects)")
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
