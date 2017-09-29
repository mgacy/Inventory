//
//  InvoiceDateViewController.swift
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

class InvoiceDateViewController: UITableViewController, RootSectionViewController {

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
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        title = "Invoices"
        self.refreshControl?.addTarget(self, action: #selector(InvoiceDateViewController.refreshTable(_:)),
                                       for: UIControlEvents.valueChanged)
        setupTableView()

        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED: unable to get storeID"); return
        }

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
        guard let controller = segue.destination as? InvoiceVendorViewController else {
            fatalError("Wrong view controller type")
        }
        guard let selection = selectedCollection else {
            fatalError("Showing detail, but no selected row?")
        }
        controller.parentObject = selection
        controller.managedObjectContext = managedObjectContext
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceDateViewController>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "dateA", ascending: false)
        request.sortDescriptors = [sortDescriptor]

        //let fetchPredicate = NSPredicate(format: "inventory == %@", inventory)
        //request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = dataSource.objectAtIndexPath(indexPath)
        guard let selection = selectedCollection else { fatalError("Unable to get selection") }
        guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID"); return
        }

        HUD.show(.progress)
        log.info("GET InvoiceCollection from server ...")
        APIManager.sharedInstance.getInvoiceCollection(
            storeID: storeID, invoiceDate: selection.date.shortDate,
            completion: completedGetInvoiceCollection)

        /// TODO: move before call to APIManager?
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

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceDateViewController: TableViewDataSourceDelegate {
    /*
    func canEdit(_ collection: InvoiceCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }
    */
    func configure(_ cell: UITableViewCell, for collection: InvoiceCollection) {
        cell.textLabel?.text = collection.date.altStringFromDate()
        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}

// MARK: - Completion Handlers + Sync
extension InvoiceDateViewController {

    // MARK: Completion Handlers

    func completedGetListOfInvoiceCollections(json: JSON?, error: Error?) {
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
            try managedObjectContext.syncCollections(InvoiceCollection.self, withJSON: json)
            //try InvoiceCollection.sync(withJSON: json, in: managedObjectContext)
        } catch let error {
            log.error("Unable to sync Invoices: \(error)")
            HUD.flash(.error, delay: 1.0)
        }
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetInvoiceCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            log.error("Unable to get InvoiceCollection: \(String(describing: error))")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }
        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected InvoiceCollection"); return
        }

        /// TODO: make this more elegant
        var jsonArray: [JSON] = []
        for (_, objectJSON) in json {
            jsonArray.append(objectJSON)
        }

        // Update selected Inventory with full JSON from server.
        selection.syncChildren(in: managedObjectContext!, with: jsonArray)
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedSync(_ succeeded: Bool, error: Error?) {
        if succeeded {
            log.verbose("Completed login / sync - succeeded: \(succeeded)")
            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            // Get list of Invoices from server
            log.verbose("Fetching existing InvoiceCollections from server ...")
            APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID,
                                                                  completion: self.completedGetListOfInvoiceCollections)
        } else {
            // if let error = error { // present more detailed error ...
            log.error("Unable to sync: \(String(describing: error))")
            refreshControl?.endRefreshing()
            HUD.flash(.error, delay: 1.0)
        }
    }

}
