//
//  OrderItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import PKHUD

class OrderItemTVC: UITableViewController {

    // MARK: - Properties

    var parentObject: Order!
    var selectedObject: OrderItem?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    var _fetchedResultsController: NSFetchedResultsController<OrderItem>? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = nil
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // Create a MessageComposer
    /// TODO: should I instantiate this here or only on .tappedMessageOrder(:)?
    let messageComposer = MessageComposer()

    // TableView
    var cellIdentifier = "OrderItemTableViewCell"

    // Segues
    let segueIdentifier = "showOrderKeypad"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // Set Title
        title = parentObject.vendor?.name

        // Register reusable cell
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        // CoreData
        self.performFetch()
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
        guard let destinationController = segue.destination as? OrderKeypadVC else {
            fatalError("Wrong view controller type")
        }

        // Pass the parent of the selected object to the new view controller.
        destinationController.parentObject = parentObject
        destinationController.managedObjectContext = managedObjectContext

        // FIX: fix this
        if let indexPath = self.tableView.indexPathForSelectedRow?.row {
            destinationController.currentIndex = indexPath
        }
    }

    // MARK: - User Actions

    @IBAction func tappedMessageOrder(_ sender: UIBarButtonItem) {
        log.info("Placing Order ...")

        // Prevent placing the order twice
        if parentObject.uploaded {
            log.warning("Tried to place the same Order twice")
            PKHUD.sharedHUD.show()
            PKHUD.sharedHUD.contentView = PKHUDErrorView(title: "Error", subtitle: "Order already placed")
            PKHUD.sharedHUD.hide(afterDelay: 2.0)
            return
        }

        // Simply POST the order if we already sent the message but were unable to POST if previously
        if parentObject.placed {
            log.info("Trying to POST an Order which was already sent ...")
            /// TODO: should we return after calling completedPlaceOrder
            completedPlaceOrder(true)
            return
        }

        /// TODO: handle different orderMethod
        /// TODO: prevent attempt to send empty order

        /// TODO: Enable usage of vendor.rep.phoneNumber
        //guard let phoneNumber = parentObject.vendor.rep.phoneNumber else { return }
        let phoneNumber = "602-980-4718"
        guard let message = parentObject.getOrderMessage() else {
            log.error("\(#function) FAILED : unable to getOrderMessage"); return
        }

        log.verbose("Order message: \(message)")

        // Make sure the device can send text messages
        if (messageComposer.canSendText()) {

            // Obtain a configured MFMessageComposeViewController
            let messageComposeVC = messageComposer.configuredMessageComposeViewController(
                phoneNumber: phoneNumber, message: message,
                completionHandler: completedPlaceOrder)

            // Present the configured MFMessageComposeViewController instance
            // Note that the dismissal of the VC will be handled by the messageComposer instance,
            // since it implements the appropriate delegate call-back
            present(messageComposeVC, animated: true, completion: nil)

        } else {
            log.error("\(#function) FAILED : messageComposer cannot send text")
            /// TODO: try to send email message?

            // TESTING:
            completedPlaceOrder(true)

            // Let the user know if his/her device isn't able to send text messages
            let errorAlert = createAlert(
                title: "Cannot Send Text Message",
                message: "Your device is not able to send text messages.",
                handler: nil)

            present(errorAlert, animated: true, completion: nil)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)

        // OLD
        //let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell

        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let orderItem = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = orderItem.item?.name

        /// TODO: pack?

        /// TODO: on hand?

        /// TODO: par

        guard let quantity = orderItem.quantity else { return }
        if Double(quantity) > 0.0 {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.text = "\(quantity) \(orderItem.orderUnit?.abbreviation ?? "")"
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            /// TODO: should I even bother displaying quantity?
            cell.detailTextLabel?.text = "\(quantity)"
        }
        /// TODO: add warning color if quantity < suggested (excluding when par = 1 and suggested < 0.x)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = self.fetchedResultsController.object(at: indexPath)
        // log.verbose("Selected OrderItem: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - Completion Handlers
extension OrderItemTVC {

    func completedPlaceOrder(_ succeeded: Bool) {
        if succeeded {
            parentObject.placed = true

            HUD.show(.progress)

            // Serialize and POST Order
            guard let json = parentObject.serialize() else {
                log.error("\(#function) FAILED : unable to serialize Order")
                /// TODO: show more detailed error message
                HUD.flash(.error, delay: 1.0); return
            }

            log.info("POSTing Order ...")
            log.verbose("Order: \(json)")
            APIManager.sharedInstance.postOrder(order: json, completion: completedPostOrder)
        } else {
            log.error("\(#function) FAILED : unable to send Order message")
            showAlert(title: "Problem", message: "Unable to send Order message")
        }
    }

    /// TODO: change completion handler to accept standard (JSON?, Error?)

    func completedPostOrder(succeeded: Bool, json: JSON) {
        if succeeded {
            parentObject.uploaded = true

            /// TODO: set .uploaded of parentObject.collection if all are uploaded

            HUD.flash(.success, delay: 1.0) { finished in
                // Pop view
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            print("\nPROBLEM - Unable to POST order \(json)")
            showAlert(title: "Problem", message: "Unable to upload Order")
        }
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension  OrderItemTVC {

    var fetchedResultsController: NSFetchedResultsController<OrderItem> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = fetchBatchSize

        // Edit the sort key as appropriate.
        /// TODO: sort by item.category.name as well?
        // let categorySortDescriptor = NSSortDescriptor(key: "item.category.name", ascending: true)
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate
        let fetchPredicate = NSPredicate(format: "order == %@", parentObject)
        fetchRequest.predicate = fetchPredicate

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
extension OrderItemTVC: NSFetchedResultsControllerDelegate {

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

// MARK: - Notifications
extension OrderItemTVC {

    // If we pass a handler, display a "Cancel" and an "OK" button with the latter calling that handler
    // Otherwise, display a single "OK" button
    /// TODO: shouldn't we allow the specification of the okAction's title?
    /// TODO: should we just present the alert within the function instead of returning it?
    func createAlert(title: String, message: String, handler: (() -> Void)? = nil) -> UIAlertController {

        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelTitle: String

        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        return alert
    }

    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {

        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)

        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"

            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)

        case false:
            cancelTitle = "OK"
        }

        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }

}
