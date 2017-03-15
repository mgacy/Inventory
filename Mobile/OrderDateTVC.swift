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

class OrderDateTVC: UITableViewController {

    // MARK: Properties

    let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
    //var userManager: CurrentUserManager!
    var selectedCollection: OrderCollection?
    //var selectedCollectionIndex: IndexPath?

    // MARK: FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var _fetchedResultsController: NSFetchedResultsController<OrderCollection>? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showOrderVendors"

    // TODO - provide interface to control these
    let orderTypeID = 1

    // MARK: - Lifecycle

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

        // Get list of OrderCollections from server
        // print("\nFetching existing OrderCollections from server ...")

        guard let storeID = userManager.storeID else {
            print("\(#function) FAILED: unable to get storeID"); return
        }
        HUD.show(.progress)
        APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID, completion: self.completedGetListOfOrderCollections)
    }

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

        // Get the new view controller.
        guard let controller = segue.destination as? OrderVendorTVC else { return }

        // Get the selection
        guard let selection = selectedCollection else { return }

        // Pass selection to new view controller.
        controller.parentObject = selection
        controller.managedObjectContext = self.managedObjectContext
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
        //selectedCollectionIndex = indexPath
        guard let selection = selectedCollection else { return }

        switch selection.uploaded {
        case true:

            // Get date to use when getting OrderCollection from server
            guard let collectionDate = selection.date else {
                print("\(#function) FAILED : unable to get orderCollection.date"); return
            }
            guard let storeID = userManager.storeID else {
                print("\(#function) FAILED : unable to get storeID"); return
            }

            //tableView.activityIndicatorView.startAnimating()
            HUD.show(.progress)

            // TODO - ideally, we would want to deleteChildOrders *after* fetching data from server
            // Delete existing orders of selected collection
            print("Deleting Orders of selected OrderCollection ...")
            deleteChildOrders(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteChildOrders
            selectedCollection = self.fetchedResultsController.object(at: indexPath)

            print("GET OrderCollection from server ...")
            APIManager.sharedInstance.getOrderCollection(
                storeID: storeID, orderDate: collectionDate,
                completion: completedGetExistingOrderCollection)

        case false:
            print("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @IBAction func newTapped(_ sender: AnyObject) {

        // TODO - check if there is already an Order for the current date and of the current type

        guard let storeID = userManager.storeID else {
            print("\(#function) FAILED : unable to get storeID"); return
        }

        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        // Get new OrderCollection.
        APIManager.sharedInstance.getNewOrderCollection(
            storeID: storeID, typeID: orderTypeID, returnUsage: true,
            periodLength: 28, completion: completedGetNewOrderCollection)
    }

    @IBAction func resetTapped(_ sender: AnyObject) {
        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        deleteObjects(entityType: Item.self)
        deleteExistingOrderCollections()

        _ = SyncManager(storeID: userManager.storeID!, completionHandler: completedLogin)
    }

}

// MARK: - Completion Handlers + Sync
extension OrderDateTVC {

    // MARK: Completion Handlers

    func completedGetListOfOrderCollections(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED : no JSON")
            HUD.hide(); return
        }

        HUD.hide()

        // FIX - this does not account for Collections that have been deleted from the server but
        // are still present in the local store
        for (_, collection) in json {
            guard let dateString = collection["date"].string else {
                print("unable to get date"); continue
            }

            // Create OrderCollection if we can't find one with date `date`
            if OrderCollection.fetchByDate(context: managedObjectContext!, date: dateString) == nil {
                // print("Creating OrderCollection: \(dateString)")
                _ = OrderCollection(context: self.managedObjectContext!, json: collection, uploaded: true)
            }
        }

        // Save the context.
        saveContext()
    }

    func completedGetExistingOrderCollection(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED : no JSON")
            HUD.flash(.error, delay: 1.0); return
        }

        /*
        guard let selectedCollectionIndex = selectedCollectionIndex else {
            print("\nPROBLEM - 1a"); return
        }
        var selection: OrderCollection
        selection = self.fetchedResultsController.object(at: selectedCollectionIndex)

        // Delete existing orders of selected collection
        print("Deleting Orders of selected OrderCollection ...")
        deleteChildOrders(parent: selection)

        // Reset selection since we reset the managedObjectContext in deleteChildOrders
        selection = self.fetchedResultsController.object(at: selectedCollectionIndex)
        */

        guard let selection = selectedCollection else {
            print("\(#function) FAILED : still unable to get selected OrderCollection\n")
            HUD.flash(.error, delay: 1.0); return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)

        // Save the context.
        saveContext()

        //tableView.activityIndicatorView.stopAnimating()
        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewOrderCollection(json: JSON?, error: Error?) -> Void {
        guard error == nil else {
            print("\(#function) FAILED : \(error)")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED : no JSON")
            HUD.flash(.error, delay: 1.0); return
        }
        //print("\nCreating new OrderCollection ...")
        selectedCollection = OrderCollection(context: self.managedObjectContext!, json: json, uploaded: false)

        // Save the context.
        saveContext()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedLogin(_ succeeded: Bool, _ error: Error?) {
        if succeeded {
            print("\nCompleted login / sync - succeeded: \(succeeded)")

            guard let storeID = userManager.storeID else {
                print("\(#function) FAILED : unable to get storeID")
                HUD.flash(.error, delay: 1.0)
                return
            }

            // Get list of OrderCollections from server
            // print("\nFetching existing OrderCollections from server ...")
            APIManager.sharedInstance.getListOfOrderCollections(storeID: storeID, completion: self.completedGetListOfOrderCollections)

        } else {
            print("Unable to login / sync ...")
            // if let error = error { // present more detailed error ...
            HUD.flash(.error, delay: 1.0)
        }
    }

    // MARK: Sync

    func deleteExistingOrderCollections(_ filter: NSPredicate? = nil) {
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

    // Source: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-deletes--cms-25380
    // NOTE - I believe I scrapped a plan to make this a method because of the involvement of the moc
    func deleteChildOrders(parent: OrderCollection) {
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

        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Order> = Order.fetchRequest()

        // Configure Fetch Request
        fetchRequest.predicate = NSPredicate(format: "collection == %@", parent)

        // Initialize Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount
        //batchDeleteRequest.resultType = .resultTypeStatusOnly

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult

            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")

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

    func resetData() {
        deleteObjects(entityType: Item.self)
        deleteObjects(entityType: Unit.self)
        deleteObjects(entityType: Vendor.self)
    }

    func deleteObjects<T: NSManagedObject>(entityType: T.Type, filter: NSPredicate? = nil) {

        // Create Fetch Request
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>

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
            //try self.fetchedResultsController.performFetch()

            // Reload Table View
            tableView.reloadData()

        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension OrderDateTVC {

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
extension OrderDateTVC: NSFetchedResultsControllerDelegate {

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
