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

class OrderItemViewController: UIViewController {

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
    let cellIdentifier = "OrderItemCell"

    // MARK: - Display Outlets
    @IBOutlet weak var repNameTextLabel: UILabel!
    @IBOutlet weak var messageButton: RoundButton!
    @IBOutlet weak var emailButton: RoundButton!
    @IBOutlet weak var callButton: RoundButton!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = parentObject.vendor?.name
        tableView.delegate = self
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

    fileprivate func showKeypad(withItem item: OrderItem) {
        guard let destinationController = OrderKeypadViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        guard
            let indexPath = self.tableView.indexPathForSelectedRow?.row,
            let managedObjectContext = managedObjectContext else {
                fatalError("\(#function) FAILED: unable to get indexPath or moc")
        }

        destinationController.viewModel = OrderKeypadViewModel(for: parentObject, atIndex: indexPath,
                                                               inContext: managedObjectContext)
        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderItemViewController>!

    fileprivate func setupTableView() {
        //tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 80

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        let fetchPredicate = NSPredicate(format: "order == %@", parentObject)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    func setupView() {
        repNameTextLabel.text = viewModel.repName

        callButton.setBackgroundColor(color: UIColor.lightGray, forState: .disabled)
        emailButton.setBackgroundColor(color: UIColor.lightGray, forState: .disabled)
        messageButton.setBackgroundColor(color: UIColor.lightGray, forState: .disabled)

        /// NOTE: disable for testing
        guard messageComposer.canSendText() else {
            messageButton.isEnabled = false
            return
        }

        /// TODO: handle orders that have been placed but not uploaded; display different `upload` button
        callButton.isEnabled = false
        emailButton.isEnabled = false
        messageButton.isEnabled = viewModel.canMessageOrder
    }

    // MARK: - User Actions

    @IBAction func tappedMessageButton(_ sender: Any) {
        log.debug("Send message ...")

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

    @IBAction func tappedEmailButton(_ sender: Any) {
        log.debug("Email message ...")
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

            HUD.flash(.success, delay: 0.5) { _ in
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            log.error("\(#function) FAILED : unable to POST order \(json)")
            HUD.flash(.error, delay: 1.0)
            //showAlert(title: "Problem", message: "Unable to upload Order")
        }
    }

}

// MARK: - UITableViewDelegate Extension
extension OrderItemViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected Order: \(String(describing: selectedObject))")
        guard let selection = selectedObject else {
            fatalError("Couldn't get selected Order")
        }
        showKeypad(withItem: selection)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderItemViewController: TableViewDataSourceDelegate {

    func configure(_ cell: OrderItemTableViewCell, for orderItem: OrderItem) {
        cell.configure(forOrderItem: orderItem)
        //let viewModel = OrderItemCellViewModel(forOrderItem: orderItem)
        //cell.configure(withViewModel: viewModel)
    }

}
