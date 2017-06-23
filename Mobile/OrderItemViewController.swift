//
//  OrderItemViewController.swift
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

class OrderItemViewController: UITableViewController {

    // MARK: - Properties

    var viewModel: OrderViewModel!
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
        // Update in case we have returned from the keypad where we updated the quantity of an OrderItem
        parentObject.updateStatus()
        setupView()
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
    fileprivate var dataSource: TableViewDataSource<OrderItemViewController>!

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

        guard let phoneNumber = parentObject.vendor?.rep?.phone else {
            log.error("Unable to get phoneNumber"); return
        }
        //let phoneNumber = "602-980-4718"
        guard let message = viewModel.orderMessage else {
            log.error("\(#function) FAILED : unable to getOrderMessage"); return
        }

        let messageComposeVC = messageComposer.configuredMessageComposeViewController(
            phoneNumber: phoneNumber, message: message,
            completionHandler: completedPlaceOrder)
        present(messageComposeVC, animated: true, completion: nil)
    }

    func setupView() {
        /// NOTE: disable for testing
        guard messageComposer.canSendText() else {
            messageButton.isEnabled = false
            return
        }

        /// TODO: handle orders that have been placed but not uploaded; display different `upload` button
        messageButton.isEnabled = viewModel.canMessageOrder
    }

}

// MARK: - Completion Handlers
extension OrderItemViewController {

    func completedPlaceOrder(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            log.info("Message was cancelled")
        case .failed:
            log.error("\(#function) FAILED : unable to send Order message")
            showAlert(title: "Problem", message: "Unable to send Order message")
        case .sent:
            log.info("Sent Order message")
            HUD.show(.progress)
            /// TODO: simply pass closure?
            viewModel.postOrder(completion: completedPostOrder)
        }
    }

    /// TODO: change completion handler to accept standard (JSON?, Error?)

    func completedPostOrder(succeeded: Bool, json: JSON) {
        if succeeded {
            viewModel.completedPostOrder()

            // swiftlint:disable:next unused_closure_parameter
            HUD.flash(.success, delay: 0.5) { finished in
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
extension OrderItemViewController: TableViewDataSourceDelegate {

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
