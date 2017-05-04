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

class InvoiceItemTVC: UITableViewController {

    // MARK: - Properties

    var parentObject: Invoice!
    var selectedObject: InvoiceItem?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate? = nil
    //var cacheName: String? = nil
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableView
    var cellIdentifier = "InvoiceItemCell"

    // Segues
    let segueIdentifier = "showInvoiceKeypad"

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
        guard let destinationController = segue.destination as? InvoiceKeypadVC else {
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

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceItemTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        let fetchPredicate = NSPredicate(format: "invoice == %@", parentObject)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - User interaction

    @IBAction func uploadTapped(_ sender: AnyObject) {
        log.info("Uploading Invoice ...")

        guard let dict = self.parentObject.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Invoice")
            /// TODO: completedUpload(false)
            return
        }
        APIManager.sharedInstance.postInvoice(invoice: dict, completion: completedUpload)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected InvoiceItem: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let invoiceItem = dataSource.objectAtIndexPath(indexPath)
        /*
        // More Button
        let more = UITableViewRowAction(style: .normal, title: "More") { action, index in
            self.isEditing = false
            print("more button tapped")
        }
        more.backgroundColor = UIColor.lightGray
        */
        // Not Received Button
        let notReceived = UITableViewRowAction(style: .normal, title: "Not Received ...") { action, index in
            self.showNotReceivedAlert(forItem: invoiceItem)
        }
        notReceived.backgroundColor = ColorPalette.redColor

        // Received Button
        let received = UITableViewRowAction(style: .normal, title: "Received") { action, index in
            invoiceItem.status = InvoiceItemStatus.received.rawValue
            self.isEditing = false
        }
        received.backgroundColor = ColorPalette.navyColor

        return [received, notReceived]
    }

    // Support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // stuff
    }

}

// MARK: - Completion Handlers
extension InvoiceItemTVC {

    /// TODO: change signature to accept standard (JSON?, Error?)

    func completedUpload(succeeded: Bool, json: JSON) {
        if succeeded {
            parentObject.uploaded = true

            // TODO: set .uploaded of parentObject.collection if all are uploaded

            HUD.flash(.success, delay: 1.0) { finished in
                // Pop view
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            log.error("\(#function) FAILED : unable to upload Invoice")
        }
    }

}

// MARK: - Alert Controller Extension
extension InvoiceItemTVC {

    func showNotReceivedAlert(forItem invoiceItem: InvoiceItem) {

        // Generic Action Handler

        func updateItemStatus(forItem invoiceItem: InvoiceItem, withStatus status: InvoiceItemStatus) {
            self.isEditing = false
            invoiceItem.status = status.rawValue
            log.info("Updated InvoiceItem: \(invoiceItem)")
        }

        // Alert Controller
        let alertController = UIAlertController(title: nil,message: "Why wasn't this item received?",
                                                preferredStyle: .actionSheet)

        // Actions

        /// TODO: use InvoiceItemStatus.description for alert action title?

        // damaged
        let damagedAction = UIAlertAction(title: "Damaged", style: .default, handler: { (action:UIAlertAction!) -> Void in
            updateItemStatus(forItem: invoiceItem, withStatus: .damaged)
        })
        alertController.addAction(damagedAction)

        // outOfStock
        let outOfStockAction = UIAlertAction(title: "Out of Stock", style: .default, handler: { (action:UIAlertAction!) -> Void in
            updateItemStatus(forItem: invoiceItem, withStatus: .outOfStock)
        })
        alertController.addAction(outOfStockAction)

        // wrongItem
        let wrontItemAction = UIAlertAction(title: "Wrong Item", style: .default, handler: { (action: UIAlertAction) -> Void in
            updateItemStatus(forItem: invoiceItem, withStatus: .wrongItem)
        })
        alertController.addAction(wrontItemAction)

        // cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in
            self.isEditing = false
        })
        alertController.addAction(cancelAction)

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
extension InvoiceItemTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoiceItem: InvoiceItem) {
        cell.textLabel?.text = invoiceItem.item?.name
        cell.detailTextLabel?.textColor = UIColor.lightGray

        /// TODO: pack

        /// TODO: cost

        //guard let quantity = invoiceItem.quantity else { return }
        let quantity = invoiceItem.quantity
        if Double(quantity) > 0.0 {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.text = "\(quantity) \(invoiceItem.unit?.abbreviation ?? "")"
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            /// TODO: should I even both displaying quantity?
            cell.detailTextLabel?.text = "\(quantity)"
        }

        switch invoiceItem.status {
        case InvoiceItemStatus.pending.rawValue:
            cell.textLabel?.textColor = UIColor.lightGray
        // Received
        case InvoiceItemStatus.received.rawValue:
            cell.textLabel?.textColor = UIColor.black
        // Not Received
        case InvoiceItemStatus.damaged.rawValue:
            cell.textLabel?.textColor = ColorPalette.redColor
        case InvoiceItemStatus.outOfStock.rawValue:
            cell.textLabel?.textColor = ColorPalette.redColor
        case InvoiceItemStatus.wrongItem.rawValue:
            cell.textLabel?.textColor = ColorPalette.redColor
        // Other
        case InvoiceItemStatus.promo.rawValue:
            cell.textLabel?.textColor = ColorPalette.navyColor
        case InvoiceItemStatus.substitute.rawValue:
            cell.textLabel?.textColor = ColorPalette.navyColor

        default:
            log.warning("\(#function) : unrecognized status")
            // cell.textLabel?.textColor = UIColor.lightGray
        }
    }
    
}
