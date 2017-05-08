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
    var managedObjectContext: NSManagedObjectContext!
    //var filter: NSPredicate? = nil
    //var cacheName: String? = "Master"
    //var sectionNameKeyPath: String? = nil
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
        // Display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        title = "Invoices"

        // Add refresh control
        self.refreshControl?.addTarget(self, action: #selector(InvoiceDateTVC.refreshTable(_:)),
                                       for: UIControlEvents.valueChanged)

        setupTableView()

        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED: unable to get storeID"); return
        }

        // Get list of InvoiceCollections from server
        HUD.show(.progress)
        APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID,
                                                              completion: self.completedGetListOfInvoiceCollections)
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

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceDateTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        //let fetchPredicate = NSPredicate(format: "inventory == %@", inventory)
        //request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = CustomDeletionDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                              fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = dataSource.objectAtIndexPath(indexPath)
        guard let selection = selectedCollection else { fatalError("Unable to get selection") }

        switch selection.uploaded {
        case true:

            // Get date to use when getting InvoiceCollection from server
            guard
                let storeID = userManager.storeID,
                let collectionDate = selection.date else {
                    log.error("\(#function) FAILED : unable to get storeID or collection date"); return
            }

            HUD.show(.progress)

            /// TODO: ideally, we would want to deleteChildOrders *after* fetching data from server
            // Delete existing invoices of selected collection
            log.verbose("Deleting Invoices of selected InvoiceCollection ...")
            deleteChildInvoices(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteChildOrders
            selectedCollection = dataSource.objectAtIndexPath(indexPath)
            log.info("GET InvoiceCollection from server ...")
            APIManager.sharedInstance.getInvoiceCollection(
                storeID: storeID, invoiceDate: collectionDate,
                completion: completedGetExistingInvoiceCollection)

        case false:
            log.verbose("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User interaction

    func refreshTable(_ refreshControl: UIRefreshControl) {
        guard let storeID = userManager.storeID else { return }

        //HUD.show(.progress)
        _ = SyncManager(context: managedObjectContext, storeID: storeID, completionHandler: completedSync)

        //self.tableView.reloadData()
        //refreshControl.endRefreshing()
    }

    @IBAction func newTapped(_ sender: AnyObject) {
        guard let storeID = userManager.storeID else {
            fatalError("Unable to get storeID")
        }
        //refreshControl?.beginRefreshing()
        HUD.show(.progress)
        APIManager.sharedInstance.getNewInvoiceCollection(
            storeID: storeID, completion: completedGetNewInvoiceCollection)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceDateTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for collection: InvoiceCollection) {
        cell.textLabel?.text = collection.date

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}

// MARK: - CustomDeletionDataSourceDelegate Extension (supports property-dependent row deletion)
extension InvoiceDateTVC: CustomDeletionDataSourceDelegate {

    func canEdit(_ collection: InvoiceCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

}

// MARK: - Completion Handlers + Sync
extension InvoiceDateTVC {

    // MARK: Completion Handlers

    func completedGetListOfInvoiceCollections(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        do {
            try managedObjectContext.syncCollections(InvoiceCollection.self, withJSON: json)
        } catch {
            log.error("Unable to sync Inventories")
            HUD.flash(.error, delay: 1.0)
        }

        refreshControl?.endRefreshing()
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetExistingInvoiceCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }
        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected InvoiceCollection"); return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: managedObjectContext!, json: json)
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewInvoiceCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        //log.info("Creating new InvoiceCollection(s) ...")
        for (_, collection) in json {
            _ = InvoiceCollection(context: managedObjectContext!, json: collection, uploaded: false)
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
            APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID,
                                                                  completion: self.completedGetListOfInvoiceCollections)

        } else {
            // if let error = error { // present more detailed error ...
            log.error("Unable to sync ...")
            HUD.flash(.error, delay: 1.0)
        }
    }

    // MARK: Sync

    func deleteChildInvoices(parent: InvoiceCollection) {
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
            log.error("Unable to delete Invoices: \(updateError), \(updateError.userInfo)")
        }
    }

}
