//
//  InvoiceDateTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import PKHUD

class InvoiceDateTVC: UITableViewController, RootSectionViewController {

    // MARK: - Properties

    var userManager: CurrentUserManager!
    var selectedCollection: InvoiceCollection?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var _fetchedResultsController: NSFetchedResultsController<InvoiceCollection>? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showInvoiceVendors"

    /// TODO: provide interface to control these
    // let invoiceTypeID = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        title = "Invoices"

        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        // Add refresh control
        self.refreshControl?.addTarget(self, action: #selector(InvoiceDateTVC.refreshTable(_:)), for: UIControlEvents.valueChanged)

        // CoreData
        self.performFetch()

        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED: unable to get storeID"); return
        }

        // Get list of Invoices from server
        HUD.show(.progress)
        APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID, completion: self.completedGetListOfInvoiceCollections)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? InvoiceVendorTVC else {
            fatalError("Wrong view controller type")
        }
        guard let selection = selectedCollection else {
            fatalError("Showing detail, but no selected row?")
        }

        // Pass selection to new view controller.
        controller.parentObject = selection
        controller.managedObjectContext = managedObjectContext
    }

    // MARK: - User interaction

    func refreshTable(_ refreshControl: UIRefreshControl) {
        guard let managedObjectContext = managedObjectContext else { return }
        guard let storeID = userManager.storeID else { return }

        /// TODO: SyncManager?
        //_ = SyncManager(storeID: userManager.storeID!, completionHandler: completedSync)

        // Reload data and update the table view's data source
        APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID, completion: {(json: JSON?, error: Error?) in
            guard error == nil, let json = json else {
                HUD.flash(.error, delay: 1.0); return
            }
            do {
                try managedObjectContext.syncCollections(InvoiceCollection.self, withJSON: json)
            } catch {
                log.error("Unable to sync InvoiceCollections")
            }
        })

        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

    @IBAction func newTapped(_ sender: AnyObject) {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        // Get new InvoiceCollection.
        APIManager.sharedInstance.getNewInvoiceCollection(
            storeID: storeID, completion: completedGetNewInvoiceCollection)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    // MARK: Editing

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let collection = self.fetchedResultsController.object(at: indexPath)
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            // Fetch Collection
            let collection = fetchedResultsController.object(at: indexPath)

            // Delete Collection
            fetchedResultsController.managedObjectContext.delete(collection)
        }
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let collection = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = collection.date

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = self.fetchedResultsController.object(at: indexPath)
        guard let selection = selectedCollection else { return }

        switch selection.uploaded {
        case true:

            // Get date to use when getting OrderCollection from server
            guard let storeID = userManager.storeID,
                  let collectionDate = selection.date else
            {
                log.error("\(#function) FAILED : unable to get storeID"); return
            }

            /// TODO: ideally, we would want to deleteChildOrders *after* fetching data from server
            // Delete existing invoices of selected collection
            log.verbose("Deleting Invoices of selected InvoiceCollection ...")
            deleteChildInvoices(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteChildOrders
            selectedCollection = self.fetchedResultsController.object(at: indexPath)

            log.verbose("GET InvoiceCollection from server ...")
            APIManager.sharedInstance.getInvoiceCollection(
                storeID: storeID, invoiceDate: collectionDate,
                completion: completedGetExistingInvoiceCollection)

        case false:
            log.verbose("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - Completion Handlers + Sync
extension InvoiceDateTVC {

    // MARK: Completion Handlers

    func completedGetListOfInvoiceCollections(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        // FIX - this does not account for Collections that have been deleted from the server but
        // are still present in the local store
        for (_, collection) in json {
            guard let dateString = collection["date"].string else {
                log.warning("unable to get date"); continue
            }

            // Create InvoiceCollection if we can't find one with date `date`
            // if InvoiceCollection.fetchByDate(context: managedObjectContext!, date: dateString) == nil {
            let predicate = NSPredicate(format: "date == %@", dateString)
            if managedObjectContext?.fetchSingleEntity(InvoiceCollection.self, matchingPredicate: predicate) == nil {
                log.verbose("Creating InvoiceCollection: \(dateString)")
                _ = InvoiceCollection(context: self.managedObjectContext!, json: collection, uploaded: true)
            }
        }

        managedObjectContext!.performSaveOrRollback()
        HUD.hide()
    }

    func completedGetExistingInvoiceCollection(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }
        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected InvoiceCollection\n"); return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewInvoiceCollection(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        //print("\nCreating new InvoiceCollection(s) ...")
        for (_, collection) in json {
            _ = InvoiceCollection(context: self.managedObjectContext!, json: collection, uploaded: false)
        }

        managedObjectContext!.performSaveOrRollback()
        HUD.hide()

        /// TODO: if we only added one collection, select it and performSegue
        //selectedCollection = ...
        //performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedSync(_ succeeded: Bool, error: Error?) {
        if succeeded {
            log.verbose("Completed login / sync - succeeded: \(succeeded)")

            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            // Get list of Invoices from server
            // log.info("Fetching existing InvoiceCollections from server ...")
            APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID, completion: self.completedGetListOfInvoiceCollections)

        } else {
            log.error("Unable to login / sync ...")
            // if let error = error { // present more detailed error ...
            HUD.flash(.error, delay: 1.0)
        }
    }

    // MARK: Sync

    func deleteChildInvoices(parent: InvoiceCollection) {
        guard let managedObjectContext = managedObjectContext else { return }
        let fetchPredicate = NSPredicate(format: "collection == %@", parent)
        do {
            try managedObjectContext.deleteEntities(Invoice.self, filter: fetchPredicate)

            /// TODO: perform fetch again?
            //let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
            //let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            //request.sortDescriptors = [sortDescriptor]
            //dataSource.reconfigureFetchRequest(request)

            // Reload Table View
            tableView.reloadData()

        } catch {
            let updateError = error as NSError
            log.error("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InvoiceDateTVC {

    var fetchedResultsController: NSFetchedResultsController<InvoiceCollection> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()

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
                log.error("\(#function) FAILED : \(error)")
            }
            self.tableView.reloadData()
        })
    }

}

// MARK: - NSFetchedResultsControllerDelegate Extension
extension InvoiceDateTVC: NSFetchedResultsControllerDelegate {

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
            //tableView.insertRows(at: [newIndexPath!], with: .fade)
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            //tableView.deleteRows(at: [indexPath!], with: .fade)
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            //configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, atIndexPath: indexPath)
            }
            break;
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}
