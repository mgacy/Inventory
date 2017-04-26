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

class InventoryDateTVC: UITableViewController, RootSectionViewController {

    // MARK: Properties

    var destinationController: UIViewController?
    var selectedInventory: Inventory?
    var userManager: CurrentUserManager!

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    //let filter: NSPredicate? = nil
    //let cacheName: String? = "Master"
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"

    // Segues
    let NewItemSegue = "FetchExistingInventory"
    let ExistingItemSegue = "ShowLocationCategory"
    let SettingsSegue = "ShowSettings"
    /*
    /// TODO: make enum?
    enum SegueIdentifiers : String {
        case newItemSegue = "FetchExistingInventory"
        case existingItemSegue = "ShowLocationCategory"
        case settingsSegue = "ShowSettings"
    }
    */

    /// TODO: provide interface to control these
    // let inventoryTypeID = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false

        // Display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        title = "Inventories"

        // Add refresh control
        self.refreshControl?.addTarget(self, action: #selector(InventoryDateTVC.refreshTable(_:)), for: UIControlEvents.valueChanged)

        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case NewItemSegue:
            guard let controller = segue.destination as? InventoryLocationTVC else {
                fatalError("Wrong view controller type")
            }
            guard let selection = selectedInventory else {
                fatalError("Showing detail, but no selected row?")
            }

            // Pass selection to new view controller.
            controller.inventory = selection
            controller.managedObjectContext = self.managedObjectContext

        case ExistingItemSegue:
            guard let controller = segue.destination as? InventoryLocationCategoryTVC else {
                fatalError("Wrong view controller type")
            }

            // Pass selection to new view controller.
            guard let selection = selectedInventory, let locations = selection.locations?.allObjects else {
                fatalError("Unable to get selection")
            }

            // Exisitng Inventories should have 1 Location - "Default"
            guard let defaultLocation = locations[0] as? InventoryLocation else {
                fatalError("Unable to get Default Location")
            }
            if defaultLocation.name != "Default" {
                fatalError("Unable to get Default Location")
            }
            controller.location = defaultLocation
            controller.managedObjectContext = self.managedObjectContext

        case SettingsSegue:
            log.info("Showing Settings ...")
        default:
            fatalError("Unrecognized segue.identifier: \(segue.identifier)")
        }
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryDateTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = InventoryDateDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInventory = dataSource.objectAtIndexPath(indexPath)

        guard let selection = selectedInventory else { fatalError("Unable to get selection") }

        switch selection.uploaded {
        case true:
            //tableView.activityIndicatorView.startAnimating()
            HUD.show(.progress)

            let remoteID = Int(selection.remoteID)

            /*
            // NOTE - this is a hack for current demo, where we fake uploading an inventory
            var remoteID = Int(selection.remoteID)
            if remoteID == 0 {
                if let changedID = changeSelectionForDemo(selection: selection) {
                    remoteID = changedID
                } else {
                    log.error("\(#function) FAILED : there was a problem with changeSelectionForDemo")
                }
            }
            */

            /// TODO: ideally, we would want to deleteInventoryItems *after* fetching data from server

            // Delete existing InventoryItems of selected Inventory
            log.verbose("Deleting InventoryItems of selected Inventory ...")
            deleteChildren(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteInventoryItems
            selectedInventory = dataSource.objectAtIndexPath(indexPath)

            // GET INVENTORY FROM SERVER
            log.info("GET selectedInventory from server - \(remoteID) ...")
            APIManager.sharedInstance.getInventory(
                remoteID: remoteID,
                completion: self.completedGetExistingInventory)

        case false:
            log.info("LOAD NEW selectedInventory from disk ...")
            performSegue(withIdentifier: NewItemSegue, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    func refreshTable(_ refreshControl: UIRefreshControl) {
        guard let managedObjectContext = managedObjectContext else { return }
        guard let storeID = userManager.storeID else { return }

        /// TODO: SyncManager?
        //_ = SyncManager(storeID: storeID, completionHandler: completedLogin)

        // Reload data and update the table view's data source
        APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: {(json: JSON?, error: Error?) in
            guard error == nil, let json = json else {
                HUD.flash(.error, delay: 1.0); return
            }
            do {
                try managedObjectContext.syncEntities(Inventory.self, withJSON: json)
            } catch {
                log.error("Unable to sync Inventories")
            }

        })

        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

    @IBAction func newTapped(_ sender: AnyObject) {

        /// TODO: check if there is already an Inventory for the current date and of the current type

        guard let storeID = userManager.storeID else {
            fatalError("Unable to get storeID")
        }

        // Get new Inventory.
        HUD.show(.progress)
        APIManager.sharedInstance.getNewInventory(
            isActive: true, typeID: 1, storeID: storeID, completion: completedGetNewInventory)
    }

    /// TODO: Remove
    @IBAction func resetTapped(_ sender: AnyObject) {
        guard let managedObjectContext = managedObjectContext else { return }
        guard let storeID = userManager.storeID else { return }

        HUD.show(.progress)

        let fetchPredicate = NSPredicate(format: "uploaded == %@", true as CVarArg)
        do {
            try managedObjectContext.deleteEntities(Inventory.self, filter: fetchPredicate)
        } catch {
            log.error("Unable to delete Inventories")
        }

        // Get list of Inventories from server
        APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: self.completedGetListOfInventories)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryDateTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for inventory: Inventory) {
        cell.textLabel?.text = inventory.date

        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}

// MARK: - Completion Handlers + Sync
extension InventoryDateTVC {

    // MARK: - Completion Handlers

    func completedGetListOfInventories(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        HUD.hide()

        for (_, item) in json {
            guard let inventoryID = item["id"].int32 else {
                /// TODO: break or continue?
                log.warning("Unable to get inventoryID from \(item)"); break
            }

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
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let selection = selectedInventory else {
            log.error("\(#function) FAILED : Still failed to get selected Inventory")
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
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        selectedInventory = Inventory(context: self.managedObjectContext!, json: json, uploaded: false)

        // Save the context.
        saveContext()

        performSegue(withIdentifier: NewItemSegue, sender: self)
    }

    /// TODO: rename `completedItemSync`(?)
    func completedLogin(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            log.info("Completed login / sync - succeeded: \(succeeded)")

            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID"); return
            }

            // Get list of Inventories from server
            // log.info("Fetching existing Inventories from server ...")
            APIManager.sharedInstance.getListOfInventories(storeID: storeID, completion: self.completedGetListOfInventories)

        } else {
            log.error("Unable to login / sync ...")
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
            // TODO: implement this (?)
            /*
            let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            dataSource.reconfigureFetchRequest(request)
            */
            //try self.fetchedResultsController.performFetch()

            // Reload Table View
            tableView.reloadData()

        } catch {
            let updateError = error as NSError
            log.error("Unable to delete Inventories: \(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InventoryDateTVC {

    func saveContext() {
        do {
            try managedObjectContext?.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            log.error("Unresolved error \(nserror), \(nserror.userInfo)")
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

}

// MARK: - UITableViewDataSource Extension

// MARK: - UITableViewDelegate Extension

// MARK: - For Demo
extension InventoryDateTVC {

    func changeSelectionForDemo(selection: Inventory, defaultRemoteID: Int = 19) -> Int? {
        guard Int(selection.remoteID) == 0 else { return nil }
        guard let managedObjectContext = managedObjectContext else { return nil }

        log.info("Intercepting selection for the purpose of demo ...")

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Inventory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "remoteID == \(Int32(defaultRemoteID))")
        do {
            let fetchResults = try managedObjectContext.fetch(fetchRequest)
            switch fetchResults.count {
            case 0:
                log.error("\(#function) FAILED: unable to get Inventory (\(defaultRemoteID))")
                return nil
            default:
                selectedInventory = fetchResults[0] as? Inventory
                log.info("Changed selection for demo")
                return defaultRemoteID
            }

        } catch {
            log.error("\(#function) FAILED: error with request: \(error)")
            return nil
        }
    }

}

// MARK: - Add support for property-dependent row deletion

// Define protocol adding new method to TableViewDataSourceDelegate protocol
protocol InventoryDateDelegate: TableViewDataSourceDelegate {
    func canEdit(_ object: Object) -> Bool
}

// Subclass `TableViewDataSource` so we can override `.tableView(:canEditRowAt:)` and define a second delegate property which we can access (since `delegate` is `fileprivate`)
class InventoryDateDataSource<Delegate: InventoryDateDelegate>: TableViewDataSource<Delegate> {

    typealias Object = Delegate.Object
    typealias Cell = Delegate.Cell

    fileprivate weak var customDelegate: Delegate!

    // NOTE - this is required to supply necessary info (specifically Object)
    required init(tableView: UITableView, cellIdentifier: String, fetchedResultsController: NSFetchedResultsController<Object>, delegate: Delegate) {
        super.init(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: fetchedResultsController, delegate: delegate)

        self.customDelegate = delegate
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let object = objectAtIndexPath(indexPath)
        return customDelegate.canEdit(object)
    }

}

// MARK: - InventoryDateDelegate Extension
extension InventoryDateTVC: InventoryDateDelegate {

    func canEdit(_ inventory: Inventory) -> Bool {
        switch inventory.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

}
