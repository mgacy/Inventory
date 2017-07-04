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
import PKHUD

class OrderDateTVC: UITableViewController, RootSectionViewController {

    // MARK: Properties

    var userManager: CurrentUserManager!
    var selectedCollection: OrderCollection?
    //var selectedCollectionIndex: IndexPath?

    // MARK: FetchedResultsController
    var managedObjectContext: NSManagedObjectContext!
    //var filter: NSPredicate? = nil
    //var cacheName: String? = "Master"
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showOrderVendors"

    /// TODO: provide interface to control these
    let orderTypeID = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        title = "Orders"
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.refreshControl?.addTarget(self, action: #selector(OrderDateTVC.refreshTable(_:)),
                                       for: UIControlEvents.valueChanged)
        setupTableView()

        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        HUD.show(.progress)
        APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID,
                                                            completion: self.completedGetListOfOrderCollections)
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
        guard let controller = segue.destination as? OrderVendorTVC else {
            fatalError("Wrong view controller type")
        }
        guard let selection = selectedCollection else {
            fatalError("Showing detail, but no selected row?")
        }
        controller.parentObject = selection
        controller.managedObjectContext = self.managedObjectContext
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderDateTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
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
        selectedCollection = dataSource.objectAtIndexPath(indexPath)
        guard let selection = selectedCollection else { fatalError("Unable to get selection") }

        switch selection.uploaded {
        case true:
            // Get date to use when getting OrderCollection from server
            guard let storeID = userManager.storeID,
                  let collectionDate = selection.date else {
                log.error("\(#function) FAILED : unable to get storeID or collection date"); return
            }

            //tableView.activityIndicatorView.startAnimating()
            HUD.show(.progress)

            /// TODO: ideally, we would want to deleteChildOrders *after* fetching data from server
            log.info("Deleting Orders of selected OrderCollection ...")
            deleteChildOrders(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteChildOrders
            selectedCollection = dataSource.objectAtIndexPath(indexPath)

            log.info("GET OrderCollection from server ...")
            APIManager.sharedInstance.getOrderCollection(
                storeID: storeID, orderDate: collectionDate,
                completion: completedGetExistingOrderCollection)

        case false:
            log.info("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    func refreshTable(_ refreshControl: UIRefreshControl) {
        guard let storeID = userManager.storeID else { return }

        //HUD.show(.progress)
        _ = SyncManager(context: managedObjectContext, storeID: storeID, completionHandler: completedSync)

        //tableView.reloadData()
        //refreshControl.endRefreshing()
    }

    @IBAction func newTapped(_ sender: AnyObject) {
        /// TODO: check if there is already an Order for the current date and of the current type
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : unable to get storeID"); return
        }

        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)
        APIManager.sharedInstance.getNewOrderCollection(
            storeID: storeID, generateFrom: .count, returnUsage: false,
            periodLength: 28, completion: completedGetNewOrderCollection)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderDateTVC: TableViewDataSourceDelegate {

    func canEdit(_ collection: OrderCollection) -> Bool {
        switch collection.uploaded {
        case true:
            return false
        case false:
            return true
        }
    }

    func configure(_ cell: UITableViewCell, for collection: OrderCollection) {
        cell.textLabel?.text = collection.date

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

}

// MARK: - Completion Handlers + Sync
extension OrderDateTVC {

    // MARK: Completion Handlers

    func completedGetListOfOrderCollections(json: JSON?, error: Error?) {
        refreshControl?.endRefreshing()
        guard error == nil else {
            //if error?._code == NSURLErrorTimedOut {}
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.warning("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }

        do {
            try managedObjectContext.syncCollections(OrderCollection.self, withJSON: json)
        } catch {
            log.error("Unable to sync OrderCollections")
            HUD.flash(.error, delay: 1.0)
        }
        HUD.hide()
        managedObjectContext.performSaveOrRollback()
        tableView.reloadData()
    }

    func completedGetExistingOrderCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        /// TODO: delete child orders after, rather than before fetching from server
        /*
        guard let selectedCollectionIndex = selectedCollectionIndex else {
            log.error("PROBLEM - 1a"); return
        }
        var selection: OrderCollection
        selection = self.fetchedResultsController.object(at: selectedCollectionIndex)

        // Delete existing orders of selected collection
        log.info("Deleting Orders of selected OrderCollection ...")
        deleteChildOrders(parent: selection)

        // Reset selection since we reset the managedObjectContext in deleteChildOrders
        selection = self.fetchedResultsController.object(at: selectedCollectionIndex)
        */

        guard let selection = selectedCollection else {
            log.error("\(#function) FAILED : still unable to get selected OrderCollection\n")
            HUD.flash(.error, delay: 1.0); return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)
        managedObjectContext!.performSaveOrRollback()

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewOrderCollection(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }
        //log.info("Creating new OrderCollection ...")
        selectedCollection = OrderCollection(context: managedObjectContext!, json: json, uploaded: false)

        // Save the context.
        managedObjectContext!.performSaveOrRollback()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedSync(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            log.info("Completed login / sync - succeeded: \(succeeded)")
            guard let storeID = userManager.storeID else {
                log.error("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0); return
            }

            // log.info("Fetching existing OrderCollections from server ...")
            APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID,
                                                                completion: self.completedGetListOfOrderCollections)

        } else {
            log.error("Unable to login / sync ...")
            // if let error = error { // present more detailed error ...
            HUD.flash(.error, delay: 1.0)
        }
    }

    // MARK: Sync

    // Source: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-deletes--cms-25380
    /// NOTE: I believe I scrapped a plan to make this a method because of the involvement of the moc
    func deleteChildOrders(parent: OrderCollection) {
        let fetchPredicate = NSPredicate(format: "collection == %@", parent)
        do {
            try managedObjectContext.deleteEntities(Order.self, filter: fetchPredicate)

            /// TODO: perform fetch again?
            //let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
            //let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            //request.sortDescriptors = [sortDescriptor]
            //dataSource.reconfigureFetchRequest(request)

            // Reload Table View
            tableView.reloadData()

        } catch {
            let updateError = error as NSError
            log.error("Unable to delete Orders: \(updateError), \(updateError.userInfo)")
        }
    }

}
