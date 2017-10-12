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

// swiftlint:disable file_length

class InventoryDateTVC: UITableViewController, RootSectionViewController, SegueHandler {

    // MARK: Properties

    var destinationController: UIViewController?
    var selectedInventory: Inventory?
    var userManager: CurrentUserManager!

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext!
    //let filter: NSPredicate? = nil
    //let cacheName: String? = "Master"
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryDateTableViewCell"

    // Segues
    enum SegueIdentifier: String {
        case showNewItem = "FetchExistingInventory"
        case showExistingItem = "ShowLocationCategory"
        case showSettings = "ShowSettings"
    }

    /// TODO: provide interface to control these
    // let inventoryTypeID = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false

        title = "Inventories"
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.refreshControl?.addTarget(self, action: #selector(InventoryDateTVC.refreshTable(_:)),
                                       for: UIControlEvents.valueChanged)
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
        switch segueIdentifier(for: segue) {
        case .showNewItem:
            guard let controller = segue.destination as? InventoryLocationTVC else {
                fatalError("Wrong view controller type")
            }
            guard let selection = selectedInventory else {
                fatalError("Showing detail, but no selected row?")
            }
            controller.inventory = selection
            controller.managedObjectContext = self.managedObjectContext

        case .showExistingItem:
            guard let controller = segue.destination as? InventoryLocationCategoryTVC else {
                fatalError("Wrong view controller type")
            }
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

        case .showSettings:
            log.info("Showing Settings ...")
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
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInventory = dataSource.objectAtIndexPath(indexPath)

        /*
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

            log.info("GET selectedInventory from server - \(remoteID) ...")
            APIManager.sharedInstance.getInventory(
                remoteID: remoteID,
                completion: self.completedGetExistingInventory)

        case false:
            log.info("LOAD NEW selectedInventory from disk ...")
            performSegue(withIdentifier: .showNewItem)
        }
         */
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @objc func refreshTable(_ refreshControl: UIRefreshControl) {
        /*
        guard let storeID = userManager.storeID else { return }

        //HUD.show(.progress)
        _ = SyncManager(context: managedObjectContext, storeID: storeID, completionHandler: completedSync)
         */
    }

    @IBAction func newTapped(_ sender: AnyObject) {
        /// TODO: check if there is already an Inventory for the current date and of the current type
        /*
        guard let storeID = userManager.storeID else {
            fatalError("Unable to get storeID")
        }

        //refreshControl?.beginRefreshing()
        HUD.show(.progress)
        APIManager.sharedInstance.getNewInventory(
            isActive: true, typeID: 1, storeID: storeID, completion: completedGetNewInventory)
         */
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryDateTVC: TableViewDataSourceDelegate {

    func canEdit(_ inventory: Inventory) -> Bool {
        switch inventory.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for inventory: Inventory) {
        cell.textLabel?.text = Date(timeIntervalSinceReferenceDate: inventory.date).altStringFromDate()
        switch inventory.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}
/*
// MARK: - Completion Handlers + Sync
extension InventoryDateTVC {

    // MARK: - Completion Handlers

    func completedGetListOfInventories(json: JSON?, error: Error?) {
        refreshControl?.endRefreshing()
        guard error == nil else {
            //if error?._code == NSURLErrorTimedOut {}
            log.error("\(#function) FAILED : \(String(describing: error))")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        do {
            try managedObjectContext.syncEntities(Inventory.self, withJSON: json)
        } catch let error {
            log.error("Unable to sync Inventories: \(error)")
            HUD.flash(.error, delay: 1.0)
        }
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetExistingInventory(json: JSON?, error: Error?) {
        guard error == nil else {
            log.error("Unable to get Inventory: \(String(describing: error))")
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
        selection.updateExisting(context: managedObjectContext!, json: json)
        managedObjectContext!.performSaveOrRollback()

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()
        performSegue(withIdentifier: .showExistingItem)
    }

    func completedGetNewInventory(json: JSON?, error: Error?) {
        guard error == nil else {
            log.error("Unable to get Inventory: \(String(describing: error))")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        selectedInventory = Inventory(context: self.managedObjectContext!, json: json, uploaded: false)
        managedObjectContext!.performSaveOrRollback()
        performSegue(withIdentifier: .showNewItem)
    }

    func completedSync(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            log.info("Completed sync - succeeded: \(succeeded)")
            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            // Get list of Inventories from server
            log.verbose("Fetching existing Inventories from server ...")
            APIManager.sharedInstance.getListOfInventories(storeID: storeID,
                                                           completion: self.completedGetListOfInventories)

        } else {
            // if let error = error { // present more detailed error ...
            log.error("Unable to sync: \(String(describing: error))")
            refreshControl?.endRefreshing()
            HUD.flash(.error, delay: 1.0); return
        }
    }

    // MARK: - Sync

    func deleteChildren(parent: Inventory) {
        let fetchPredicate = NSPredicate(format: "inventory == %@", parent)
        do {
            try managedObjectContext.deleteEntities(InventoryLocation.self, filter: fetchPredicate)
            try managedObjectContext.deleteEntities(InventoryItem.self, filter: fetchPredicate)

            /// TODO: perform fetch again?
            //let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
            //let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            //request.sortDescriptors = [sortDescriptor]
            //dataSource.reconfigureFetchRequest(request)

            tableView.reloadData()
        } catch {
            let updateError = error as NSError
            log.error("Unable to delete Inventories: \(updateError), \(updateError.userInfo)")
        }
    }

}
*/
// MARK: - For Demo
extension InventoryDateTVC {

    func changeSelectionForDemo(selection: Inventory, defaultRemoteID: Int = 19) -> Int? {
        guard Int(selection.remoteID) == 0 else { return nil }

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
