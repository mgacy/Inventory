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

        // Display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem

        title = "Inventories"

        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        // Add refresh control
        self.refreshControl?.addTarget(self, action: #selector(InventoryDateTVC.refreshTable(_:)), for: UIControlEvents.valueChanged)

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
        guard let sections = fetchedResultsController.sections else {
            return 0
        }

        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell

        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    // MARK: Editing

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let inventory = self.fetchedResultsController.object(at: indexPath)
        switch inventory.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            // Fetch Inventory
            let inventory = fetchedResultsController.object(at: indexPath)

            // Delete Inventory
            fetchedResultsController.managedObjectContext.delete(inventory)
        }
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

            /*
            // NOTE - this is a hack for current demo, where we fake uploading an inventory
            var remoteID = Int(selection.remoteID)
            if remoteID == 0 {
                if let changedID = changeSelectionForDemo(selection: selection) {
                    remoteID = changedID
                } else {
                    print("\(#function) FAILED : there was a problem with changeSelectionForDemo")
                }
            }
            */

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

    func refreshTable(_ refreshControl: UIRefreshControl) {
        guard let managedObjectContext = managedObjectContext else { return }
        guard let storeID = userManager.storeID else { return }

        // Reload data and update the table view's data source
        APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: {(json: JSON?, error: Error?) in
            guard error == nil, let json = json else {
                HUD.flash(.error, delay: 1.0); return
            }
            do {
                try managedObjectContext.syncEntities(Inventory.self, withJSON: json)
            } catch {
                print("Unable to delete Inventories")
            }

        })

        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

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
        guard let managedObjectContext = managedObjectContext else { return }
        guard let storeID = userManager.storeID else { return }

        HUD.show(.progress)

        let fetchPredicate = NSPredicate(format: "uploaded == %@", true as CVarArg)
        do {
            try managedObjectContext.deleteEntities(Inventory.self, filter: fetchPredicate)
        } catch {
            print("Unable to delete Inventories")
        }

        // Get list of Inventories from server
        APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: self.completedGetListOfInventories)
    }

}

// MARK: - Completion Handlers + Sync
extension InventoryDateTVC {

    // MARK: - Completion Handlers

    func completedGetListOfInventories(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
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
        //HUD.hide()
    }

    func completedGetExistingInventory(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
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

    // TODO - rename `completedItemSync`(?)
    func completedLogin(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            print("\nCompleted login / sync - succeeded: \(succeeded)")

            guard let storeID = userManager.storeID else {
                print("\(#function) FAILED : unable to get storeID"); return
            }

            // Get list of Inventories from server
            // print("\nFetching existing Inventories from server ...")
            APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: self.completedGetListOfInventories)

        } else {
            print("Unable to login / sync ...")
            // if let error = error { // present more detailed error ...
            HUD.flash(.error, delay: 1.0); return
        }
    }

    // MARK: - Sync

    func deleteChildren(parent: Inventory) {
        guard let managedObjectContext = managedObjectContext else { return }
        let fetchPredicate = NSPredicate(format: "inventory == %@", parent)
        do {
            try managedObjectContext.deleteEntities(InventoryLocation.self, filter: fetchPredicate)
            try managedObjectContext.deleteEntities(InventoryItem.self, filter: fetchPredicate)

            // Perform Fetch
            try self.fetchedResultsController.performFetch()

            // Reload Table View
            tableView.reloadData()

        } catch {
            // print("Unable to delete Inventories")
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
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .move:
            // TODO - look at alt method in CocoaCasts tutorial:
            // ExploringTheFetchedResultsControllerDelegateProtocol-master
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
