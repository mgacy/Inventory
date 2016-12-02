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

class InvoiceDateTVC: UITableViewController {

    // MARK: - Properties

    var selectedCollection: InvoiceCollection?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showInvoiceVendors"

    // TODO - provide interface to control these
    var storeID = 1
    // let invoiceTypeID = 1

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        title = "Invoices"

        // Register tableView cells
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()

        /*
        // 1. Check for existence of email and login. (?)
        if AuthorizationHandler.sharedInstance.userExists {
            print("User exists ...")

            // Delete any uploaded Invoices before fetching updated list.
            //deleteExistingInvoices(NSPredicate(format: "uploaded == true"))

            // Login to server, then get list of Invoices from server if successful.
            APIManager.sharedInstance.login(completionHandler: self.completedLogin)
        } else {
            print("User does not exist")
            // TODO - how to handle this?
        }

        // Login to server, get list of Items, and update store
        */

        HUD.show(.progress)
        completedLogin(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - User interaction

    @IBAction func newTapped(_ sender: AnyObject) {
        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        // Get new InvoiceCollection.
        APIManager.sharedInstance.getNewInvoiceCollection(
            storeID: storeID, completion: completedGetNewInvoiceCollection)
    }

    @IBAction func resetTapped(_ sender: AnyObject) {
        //tableView.activityIndicatorView.startAnimating()
        HUD.show(.progress)

        //deleteObjects(entityType: Item.self)
        deleteExistingInvoiceCollections()

        _ = StartupManager(completionHandler: completedLogin)
    }

    // MARK: - Completion handlers

    func completedGetListOfInvoiceCollections(json: JSON?, error: Error?) -> Void {
        //tableView.activityIndicatorView.stopAnimating()

        guard let json = json else {
            print("\(#function) FAILED : \(error)"); return
        }
        guard let dates = json["dates"].array else {
            print("\nPROBLEM - Failed to get dates")
            return
        }

        // FIX - this does not account for Collections that have been deleted from the server but
        // are still present in the local store
        for date in dates {
            if let dateString = date.string {

                // Create InvoiceCollection if we can't find one with date `date` (2)
                let predicate = NSPredicate(format: "date == %@", dateString)
                if managedObjectContext?.fetchSingleEntity(InvoiceCollection.self, matchingPredicate: predicate) == nil {
                    print("Creating InvoiceCollection: \(dateString)")
                    _ = InvoiceCollection(context: self.managedObjectContext!, date: date, uploaded: true)
                }

                /*
                 // Create InvoiceCollection if we can't find one with date `date`
                 if InvoiceCollection.fetchByDate(context: managedObjectContext!, date: dateString) == nil {
                 // print("Creating InvoiceCollection: \(dateString)")
                 _ = InvoiceCollection(context: self.managedObjectContext!, date: date, uploaded: true)
                 }
                 */
            }
        }

        // Save the context.
        saveContext()
        HUD.hide()
    }

    func completedGetExistingInvoiceCollection(json: JSON?, error: Error?) -> Void {
        //tableView.activityIndicatorView.stopAnimating()

        guard let json = json else {
            print("\(#function) FAILED : \(error)"); return
        }
        guard let selection = selectedCollection else {
            print("\nPROBLEM - Still failed to get selected InvoiceCollection\n")
            return
        }

        // Update selected Inventory with full JSON from server.
        selection.updateExisting(context: self.managedObjectContext!, json: json)

        // Save the context.
        saveContext()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedGetNewInvoiceCollection(json: JSON?, error: Error?) -> Void {
        //tableView.activityIndicatorView.stopAnimating()

        guard let json = json else {
            print("\(#function) FAILED : \(error)"); return
        }
        //print("\nCreating new InvoiceCollection ...")
        selectedCollection = InvoiceCollection(context: self.managedObjectContext!, json: json, uploaded: false)

        // Save the context.
        saveContext()

        HUD.hide()

        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    func completedLogin(_ succeeded: Bool) {
        if succeeded {
            print("\nCompleted login - succeeded: \(succeeded)")

            // Get list of Invoices from server
            // print("\nFetching existing InvoiceCollections from server ...")
            APIManager.sharedInstance.getListOfInvoiceCollections(storeID: storeID, completion: self.completedGetListOfInvoiceCollections)

        } else {
            print("Unable to login ...")
            HUD.flash(.error, delay: 1.0)
        }
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

        switch collection.uploaded {
        case true:
            cell.textLabel?.textColor = UIColor.black
        case false:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        }
    }

    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}

    // Override to support editing the table view.
    // override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}

    // Override to support rearranging the table view.
    // override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {}

    // Override to support conditional rearranging of the table view.
    // override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {}

    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}

    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCollection = self.fetchedResultsController.object(at: indexPath)
        guard let selection = selectedCollection else { return }

        switch selection.uploaded {
        case true:

            // Get date to use when getting OrderCollection from server
            guard let collectionDate = selection.date else {
                print("\nPROBLEM - Unable to get InvoiceCollection.date")
                return
            }

            // TODO - ideally, we would want to deleteChildOrders *after* fetching data from server
            // Delete existing invoices of selected collection
            print("Deleting Invoices of selected InvoiceCollection ...")
            deleteChildInvoices(parent: selection)

            // Reset selection since we reset the managedObjectContext in deleteChildOrders
            selectedCollection = self.fetchedResultsController.object(at: indexPath)

            print("GET InvoiceCollection from server ...")
            APIManager.sharedInstance.getInvoiceCollection(
                storeID: storeID, invoiceDate: collectionDate,
                completion: completedGetExistingInvoiceCollection)

        case false:
            print("LOAD NEW selectedCollection from disk ...")
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Get the new view controller.
        guard let controller = segue.destination as? InvoiceVendorTVC else {
            print("\nPROBLEM - Unable to get destination controller\n")
            return
        }

        // Pass selection to new view controller.
        if let selection = selectedCollection {
            controller.parentObject = selection
            controller.managedObjectContext = self.managedObjectContext
        } else {
            print("\nPROBLEM - Unable to get selection\n")
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

    func deleteExistingInvoiceCollections(_ filter: NSPredicate? = nil) {
        print("deleteExistingInvoices...")

        // Create Fetch Request
        let fetchRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()

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

    func deleteChildInvoices(parent: InvoiceCollection) {
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
        let fetchRequest: NSFetchRequest<Invoice> = Invoice.fetchRequest()

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

    // MARK: - Fetched results controller

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

    var _fetchedResultsController: NSFetchedResultsController<InvoiceCollection>? = nil

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
