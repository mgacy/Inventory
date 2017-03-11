//
//  InventoryDateTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import PKHUD

class InventoryDateTVC: UITableViewController {

    // MARK: Properties

    var destinationController: UIViewController?
    var selectedInventory: Inventory?
    var userManager: CurrentUserManager!

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var _fetchedResultsController: NSFetchedResultsController<Inventory>? = nil
    //var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"

    // Segues
    let NewItemSegue = "FetchExistingInventory"
    let ExistingItemSegue = "ShowLocationCategory"
    let SettingsSegue = "ShowSettings"
    /*
    // TODO - make enum?
    enum SegueIdentifiers : String {
        case newItemSegue = "FetchExistingInventory"
        case existingItemSegue = "ShowLocationCategory"
        case settingsSegue = "ShowSettings"
    }
    */

    // TODO - provide interface to control these
    // let inventoryTypeID = 1

    // MARK: - Lifecycle

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
    }

    // override func viewWillAppear(_ animated: Bool) { }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case NewItemSegue:

            // Get the new view controller.
            guard let controller = segue.destination as? InventoryLocationTVC else { return }

            //  Get the selection
            guard let selection = selectedInventory else { return }

            // Pass selection to new view controller.
            controller.inventory = selection
            controller.managedObjectContext = self.managedObjectContext

        case ExistingItemSegue:

            // Get the new view controller.
            guard let controller = segue.destination as? InventoryLocationCategoryTVC else { return }

            // Pass selection to new view controller.
            guard let selection = selectedInventory, let locations = selection.locations?.allObjects else {
                print("\(#function) FAILED : unable to get selection\n"); return
            }

            // Exisitng Inventories should have 1 Location - "Default"
            guard let defaultLocation = locations[0] as? InventoryLocation else {
                print("\(#function) FAILED : unable to get Default Location"); return
            }
            if defaultLocation.name != "Default" {
                print("\(#function) FAILED : unable to get Default Location"); return
            }
            controller.location = defaultLocation
            controller.managedObjectContext = self.managedObjectContext

        case SettingsSegue:
            print("Showing Settings ...")
        default:
            break
        }
    }

    // MARK: - UITableViewDataSource

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
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInventory = self.fetchedResultsController.object(at: indexPath)
        guard let selection = selectedInventory else { print("Unable to get selection"); return }

        switch selection.uploaded {
        case true:
            //tableView.activityIndicatorView.startAnimating()
            HUD.show(.progress)

            // TODO: enable
            let remoteID = Int(selection.remoteID)

            // TODO: remove; this is a hack for current demo, where we fake uploading an inventory
            //var remoteID = Int(selection.remoteID)
            //if remoteID == 0 {
            //    if let changedID = changeSelectionForDemo(selection: selection) {
            //        remoteID = changedID
            //    } else {
            //        print("\(#function) FAILED : there was a problem with changeSelectionForDemo")
            //    }
            //}

            // TODO - ideally, we would want to deleteInventoryItems *after* fetching data from server
            // Delete existing InventoryItems of selected Inventory
            print("Deleting InventoryItems of selected Inventory ...")
            deleteChildren(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteInventoryItems
            selectedInventory = self.fetchedResultsController.object(at: indexPath)

            // GET INVENTORY FROM SERVER
            // print("GET selectedInventory from server - \(remoteID) ...")
            APIManager.sharedInstance.getInventory(
                remoteID: remoteID,
                completion: self.completedGetExistingInventory)

        case false:
            print("LOAD NEW selectedInventory from disk ...")
            performSegue(withIdentifier: NewItemSegue, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @IBAction func newTapped(_ sender: AnyObject) {

        // TODO - check if there is already an Inventory for the current date and of the current type

        guard let storeID = userManager.storeID else {
            print("\(#function) FAILED : unable to get storeID"); return
        }

        // Get new Inventory.
        HUD.show(.progress)
        APIManager.sharedInstance.getNewInventory(
            isActive: true, typeID: 1, storeID: storeID, completion: completedGetNewInventory)
    }

    @IBAction func resetTapped(_ sender: AnyObject) {
        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        // By leaving filter as nil, we will delete all Inventories
        deleteExistingInventories()
        // Download Inventories from server again
        completedLogin(true, nil)
    }

}

// MARK: - Completion Handlers + Sync
extension InventoryDateTVC {

    // MARK: - Completion Handlers

    func completedGetListOfInventories(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            //self.noticeError(error!.localizedDescription, autoClear: true); return
            HUD.flash(.error, delay: 1.0); return
        }
        // TODO - distinguish empty response (new account) from error
        guard let json = json else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }

        HUD.hide()

        for (_, item) in json {
            guard let inventoryID = item["id"].int32 else { print("a"); break }

            if managedObjectContext?.fetchWithRemoteID(Inventory.self, withID: inventoryID) == nil {
                _ = Inventory(context: self.managedObjectContext!, json: item, uploaded: true)
            }
        }

        // Save the context.
        saveContext()

        //tableView.activityIndicatorView.stopAnimating()
        //HUD.hide()
    }

    func completedGetExistingInventory(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            //self.noticeError(error!.localizedDescription, autoClear: true); return
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let selection = selectedInventory else {
            print("\(#function) FAILED : Still failed to get selected Inventory\n")
            HUD.flash(.error, delay: 1.0); return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)

        // Save the context.
        saveContext()

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        performSegue(withIdentifier: ExistingItemSegue, sender: self)
    }

    func completedGetNewInventory(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            //self.noticeError(error!.localizedDescription, autoClear: true); return
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        selectedInventory = Inventory(context: self.managedObjectContext!, json: json, uploaded: false)

        // Save the context.
        saveContext()

        performSegue(withIdentifier: NewItemSegue, sender: self)
    }

    func completedLogin(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            print("\nCompleted login - succeeded: \(succeeded)")

            guard let storeID = userManager.storeID else {
                print("\(#function) FAILED : unable to get storeID"); return
            }

            // Get list of Inventories from server
            // print("\nFetching existing Inventories from server ...")
            APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: self.completedGetListOfInventories)

        } else {
            print("Unable to login ...")
            // if let error = error { // present more detailed error ...
            //self.noticeError("Error", autoClear: true)
            HUD.flash(.error, delay: 1.0); return
        }
    }

    // MARK: - Sync

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

    func deleteChildren(parent: Inventory) {
        guard let managedObjectContext = managedObjectContext else {
            return
        }

        /*
         Since the batch delete request directly interacts with the persistent store we need
         to make sure that any changes are first pushed to that store.
         */
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
        }

        // Create Fetch Request (1)
        let fetchRequest1: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()

        // Configure Fetch Request
        fetchRequest1.predicate = NSPredicate(format: "inventory == %@", parent)

        // Initialize Batch Delete Request
        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1 as! NSFetchRequest<NSFetchRequestResult>)

        do {
            // Execute Batch Request
            let batchDeleteResult1 = try managedObjectContext.execute(batchDeleteRequest1) as! NSBatchDeleteResult

            print("The batch delete request has deleted \(batchDeleteResult1.result!) InventoryLocations.")

        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // Create Fetch Request (2)
        let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()

        // Configure Fetch Request
        fetchRequest.predicate = NSPredicate(format: "inventory == %@", parent)

        // Initialize Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount
        //batchDeleteRequest.resultType = .resultTypeStatusOnly

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult

            print("The batch delete request has deleted \(batchDeleteResult.result!) InventoryItems.")

            // The managed object context is not notified of the consequences of the batch delete request.

            // Reset Managed Object Context
            // As the request directly interacts with the persistent store, we need need to reset the context
            // for it to be aware of the changes
            managedObjectContext.reset()

            // Perform Fetch
            try self.fetchedResultsController.performFetch()
            
            // Reload Table View
            tableView.reloadData()
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InventoryDateTVC {

    var fetchedResultsController: NSFetchedResultsController<Inventory> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()

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

}

// MARK: - NSFetchedResultsControllerDelegate Extension
extension InventoryDateTVC: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
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
            configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}

// MARK: - UITableViewDataSource Extension

// MARK: - UITableViewDelegate Extension

// MARK: - For Demo
extension InventoryDateTVC {

    func changeSelectionForDemo(selection: Inventory, defaultRemoteID: Int = 19) -> Int? {
        guard Int(selection.remoteID) == 0 else { return nil }
        guard let managedObjectContext = managedObjectContext else { return nil }

        print("Intercepting selection for the purpose of demo ...")

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Inventory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteID == \(Int32(defaultRemoteID))")
        do {
            let fetchResults = try managedObjectContext.fetch(fetchRequest)
            switch fetchResults.count {
            case 0:
                print("\(#function) FAILED: unable to get Inventory (\(defaultRemoteID))")
                return nil
            default:
                selectedInventory = fetchResults[0] as? Inventory
                print("Changed selection for demo")
                return defaultRemoteID
            }

        } catch {
            print("\(#function) FAILED: error with request: \(error)")
            return nil
        }
    }

}
