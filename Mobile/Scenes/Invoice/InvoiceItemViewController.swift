//
//  InvoiceItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import PKHUD

class InvoiceItemViewController: UITableViewController {

    // MARK: - Properties

    var parentObject: Invoice!

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate? = nil
    //var cacheName: String? = nil
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableView
    var cellIdentifier = "InvoiceItemCell"

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

    fileprivate func showKeypad(withIndexPath indexPath: IndexPath) {
        guard let destinationController = InvoiceKeypadViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        guard let managedObjectContext = managedObjectContext else {
                fatalError("\(#function) FAILED: unable to get moc")
        }

        destinationController.viewModel = InvoiceKeypadViewModel(for: parentObject, atIndex: indexPath.row,
                                                                 inContext: managedObjectContext)
        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceItemViewController>!

    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        let fetchPredicate = NSPredicate(format: "invoice == %@", parentObject)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    // MARK: - User interaction

    @IBAction func uploadTapped(_ sender: AnyObject) {
        log.info("Uploading Invoice ...")
        guard let dict = self.parentObject.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Invoice")
            /// TODO: completedUpload(false)
            return
        }
        //APIManager.sharedInstance.postInvoice(invoice: dict, completion: completedUpload)
        /// TODO: mark parentObject as having in-progress update
        HUD.show(.progress)
        let remoteID = Int(parentObject.remoteID)
        APIManager.sharedInstance.putInvoice(remoteID: remoteID, invoice: dict, completion: newCompletedUpload)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //log.verbose("Selected InvoiceItem: \(dataSource.objectAtIndexPath(indexPath))")
        showKeypad(withIndexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let invoiceItem = dataSource.objectAtIndexPath(indexPath)
        /*
        // More Button
        let more = UITableViewRowAction(style: .normal, title: "More") { action, index in
            self.isEditing = false
            log.info("more button tapped")
        }
        more.backgroundColor = UIColor.lightGray
        */
        // Not Received Button
        let notReceived = UITableViewRowAction(style: .normal, title: "Not Received ...") { _, _ in
            self.showNotReceivedAlert(forItem: invoiceItem)
        }
        notReceived.backgroundColor = ColorPalette.redColor

        // Received Button
        let received = UITableViewRowAction(style: .normal, title: "Received") { _, _ in
            invoiceItem.status = InvoiceItemStatus.received.rawValue
            self.managedObjectContext?.performSaveOrRollback()
            self.isEditing = false
        }
        received.backgroundColor = ColorPalette.navyColor

        return [received, notReceived]
    }

}

// MARK: - Completion Handlers
extension InvoiceItemViewController {

    /// TODO: change signature to accept standard (JSON?, Error?)

    func completedUpload(succeeded: Bool, json: JSON) {
        if succeeded {
            parentObject.uploaded = true

            /// TODO: set .uploaded of parentObject.collection if all are uploaded

            HUD.flash(.success, delay: 1.0) { _ in
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            log.error("\(#function) FAILED : unable to upload Invoice")
        }
    }

    func newCompletedUpload(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            log.error("\(#function) FAILED : unable to get JSON")
            HUD.hide(); return
        }
        /// TODO: mark parentObject as no longer having in-progress update
        log.debug("\(#function) RESPONSE: \(json)")
        HUD.flash(.success, delay: 1.0) { _ in
            self.navigationController!.popViewController(animated: true)
        }
    }

}

// MARK: - Alert Controller Extension
extension InvoiceItemViewController {

    func showNotReceivedAlert(forItem invoiceItem: InvoiceItem) {

        // Generic Action Handler

        func updateItemStatus(forItem invoiceItem: InvoiceItem, withStatus status: InvoiceItemStatus) {
            self.isEditing = false
            invoiceItem.status = status.rawValue
            managedObjectContext?.performSaveOrRollback()
            log.info("Updated InvoiceItem: \(invoiceItem)")
        }

        // Alert Controller
        let alertController = UIAlertController(title: nil, message: "Why wasn't this item received?",
                                                preferredStyle: .actionSheet)

        // Actions

        /// TODO: use InvoiceItemStatus.description for alert action title?

        // damaged
        alertController.addAction(UIAlertAction(title: "Damaged", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .damaged)
        }))

        // outOfStock
        alertController.addAction(UIAlertAction(title: "Out of Stock", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .outOfStock)
        }))

        // wrongItem
        alertController.addAction(UIAlertAction(title: "Wrong Item", style: .default, handler: { (_) in
            updateItemStatus(forItem: invoiceItem, withStatus: .wrongItem)
        }))

        // cancel
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.isEditing = false
        }))

        // Present Alert
        present(alertController, animated: true, completion: nil)
    }

    func showMoreAlert(forItem invoiceItem: InvoiceItem) {

        // Generic Action Handler

        // Alert Controller

        // Actions

        // Present Alert

    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceItemViewController: TableViewDataSourceDelegate {

    func canEdit(_ item: InvoiceItem) -> Bool {
        switch item.status {
        case InvoiceItemStatus.received.rawValue:
            return false
        default:
            return true
        }
    }

    func configure(_ cell: SubItemTableViewCell, for invoiceItem: InvoiceItem) {
        let viewModel = InvoiceItemCellViewModel(forInvoiceItem: invoiceItem)
        cell.configure(withViewModel: viewModel)
    }

}
