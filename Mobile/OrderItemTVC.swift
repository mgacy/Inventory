//
//  OrderItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import MessageUI
import SwiftyJSON
import PKHUD

class OrderItemTVC: UITableViewController {

    // MARK: - Properties

    var parentObject: Order!
    var selectedObject: OrderItem?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate = NSPredicate(format: "order == %@", parentObject)
    //var cacheName: String? = nil
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // Create a MessageComposer
    /// TODO: should I instantiate this here or only in `.setupView()`?
    // var mailComposer: MailComposer? = nil
    let messageComposer = MessageComposer()

    // TableView
    var cellIdentifier = "OrderItemCell"

    // Segues
    let segueIdentifier = "showOrderKeypad"

    // MARK: - Display Outlets
    @IBOutlet weak var messageButton: UIBarButtonItem!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = parentObject.vendor?.name
        setupTableView()
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
        guard
            let indexPath = self.tableView.indexPathForSelectedRow?.row,
            let managedObjectContext = managedObjectContext else {
                fatalError("Unable to get indexPath or moc")
        }

        destinationController.viewModel = OrderKeypadViewModel(for: parentObject, atIndex: indexPath,
                                                               inContext: managedObjectContext)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderItemTVC>!

    fileprivate func setupTableView() {
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        let fetchPredicate = NSPredicate(format: "order == %@", parentObject)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = dataSource.objectAtIndexPath(indexPath)
        // log.verbose("Selected OrderItem: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @IBAction func tappedMessageOrder(_ sender: UIBarButtonItem) {
        log.info("Placing Order ...")

        // Simply POST the order if we already sent the message but were unable to POST it previously
        if parentObject.placed {
            log.info("Trying to POST an Order which was already sent ...")
            completedPlaceOrder(.sent)
            return
        }

        /// TODO: handle different orderMethod
        /// TODO: prevent attempt to send empty order

        guard let phoneNumber = parentObject.vendor?.rep?.phone else {
            log.error("Unable to get phoneNumber"); return
        }
        //let phoneNumber = "602-980-4718"
        guard let message = parentObject.getOrderMessage() else {
            log.error("\(#function) FAILED : unable to getOrderMessage"); return
        }

        if messageComposer.canSendText() {
            let messageComposeVC = messageComposer.configuredMessageComposeViewController(
                phoneNumber: phoneNumber, message: message,
                completionHandler: completedPlaceOrder)
            present(messageComposeVC, animated: true, completion: nil)

        } else {
            log.error("\(#function) FAILED : messageComposer cannot send text")
            /// TODO: try to send email message?

            // TESTING:
            //completedPlaceOrder(true)

            let errorAlert = createAlert(title: "Cannot Send Text Message",
                                         message: "Your device is not able to send text messages.",
                                         handler: nil)
            present(errorAlert, animated: true, completion: nil)
        }
    }

    func setupView() {
        /// TODO: should most of the following be part of a ViewModel?
        guard
            let vendor = parentObject.vendor,
            let rep = vendor.rep else {
                messageButton.isEnabled = false
                log.warning("Unable to get vendor or rep")
                return
        }

        /// TODO: get rep.firstName, rep.lastName to display in view

        guard let phoneNumber = rep.phone else {
            /// TODO: try to get email in order to send Order that way
            messageButton.isEnabled = false
            log.warning("Unable to get phone number")
            return
        }
        /// TODO: format phoneNumber for display in view
        /// TODO: disable button if there are no Items with Orders
        log.info("phone number: \(phoneNumber)")

        /// NOTE: disable for testing
        guard messageComposer.canSendText() else {
            messageButton.isEnabled = false
            return
        }

        /// TODO: handle orders that have been placed but not uploaded; display different `upload` button

        if parentObject.uploaded {
            // Prevent placing the order twice
            messageButton.isEnabled = false
        } else {
            messageButton.isEnabled = true
        }
    }

}

// MARK: - Completion Handlers
extension OrderItemTVC {

    func completedPlaceOrder(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            log.info("Message was cancelled")
        case .failed:
            log.error("\(#function) FAILED : unable to send Order message")
            showAlert(title: "Problem", message: "Unable to send Order message")
        case .sent:
            log.info("Sent Order message")
            parentObject.placed = true
            HUD.show(.progress)

            // Serialize and POST Order
            guard let json = parentObject.serialize() else {
                log.error("\(#function) FAILED : unable to serialize Order")
                HUD.flash(.error, delay: 1.0); return
            }
            log.info("POSTing Order ...")
            log.verbose("Order: \(json)")
            APIManager.sharedInstance.postOrder(order: json, completion: completedPostOrder)
        }
    }

    /// TODO: change completion handler to accept standard (JSON?, Error?)

    func completedPostOrder(succeeded: Bool, json: JSON) {
        if succeeded {
            parentObject.uploaded = true

            /// TODO: set .uploaded of parentObject.collection if all are uploaded

            // swiftlint:disable:next unused_closure_parameter
            HUD.flash(.success, delay: 1.0) { finished in
                // Pop view
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            log.error("\(#function) FAILED : unable to POST order \(json)")
            HUD.flash(.error, delay: 1.0)
            //showAlert(title: "Problem", message: "Unable to upload Order")
        }
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderItemTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for orderItem: OrderItem) {
        cell.textLabel?.text = orderItem.item?.name
        cell.detailTextLabel?.textColor = UIColor.lightGray

        /// TODO: pack?

        /// TODO: on hand?

        /// TODO: par

        guard let quantity = orderItem.quantity else {
            // Highlight OrderItems w/o order
            cell.textLabel?.textColor = ColorPalette.yellowColor
            cell.detailTextLabel?.text = "?"
            return
        }
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
            // swiftlint:disable:next unused_closure_parameter
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
            // swiftlint:disable:next unused_closure_parameter
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
