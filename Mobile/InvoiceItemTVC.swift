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
    var _fetchedResultsController: NSFetchedResultsController<InvoiceItem>? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = nil
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableView
    var cellIdentifier = "InvoiceItemTableViewCell"

    // Segues
    let segueIdentifier = "showInvoiceKeypad"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // Set Title
        title = parentObject.vendor?.name

        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()
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

        // Get the new view controller using segue.destinationViewController.
        guard let destinationController = segue.destination as? InvoiceKeypadVC else { return }

        // Pass the parent of the selected object to the new view controller.
        destinationController.parentObject = parentObject
        destinationController.managedObjectContext = self.managedObjectContext

        // FIX: fix this
        if let indexPath = self.tableView.indexPathForSelectedRow?.row {
            destinationController.currentIndex = indexPath
        }
    }

    // MARK: - User interaction

    @IBAction func uploadTapped(_ sender: AnyObject) {
        print("Uploading Invoice ...")

        guard let dict = self.parentObject.serialize() else {
            print("\nPROBLEM - Unable to serialize Invoice")
            // TODO - completedUpload(false)
            return
        }
        APIManager.sharedInstance.postInvoice(invoice: dict, completion: completedUpload)
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

        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let invoiceItem = self.fetchedResultsController.object(at: indexPath)

        // Name
        cell.textLabel?.text = invoiceItem.item?.name

        // TODO - pack

        // TODO - cost

        //guard let quantity = invoiceItem.quantity else { return }
        let quantity = invoiceItem.quantity
        if Double(quantity) > 0.0 {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.text = "\(quantity) \(invoiceItem.unit?.abbreviation ?? "")"
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            // TODO - should I even both displaying quantity?
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
            print("z")
            // cell.textLabel?.textColor = UIColor.lightGray
        }

    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = self.fetchedResultsController.object(at: indexPath)
        print("Selected InvoiceItem: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let invoiceItem = self.fetchedResultsController.object(at: indexPath)
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

    func completedUpload(succeeded: Bool, json: JSON) {
        if succeeded {
            parentObject.uploaded = true

            // TODO: set .uploaded of parentObject.collection if all are uploaded

            HUD.flash(.success, delay: 1.0) { finished in
                // Pop view
                self.navigationController!.popViewController(animated: true)
            }

        } else {
            print("\(#function) FAILED : unable to upload Invoice")
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
            print("Updated InvoiceItem: \(invoiceItem)")
        }

        // Alert Controller
        let alertController = UIAlertController(title: nil,message: "Why wasn't this item received?",
                                                preferredStyle: .actionSheet)

        // Actions

        // TODO - use InvoiceItemStatus.description for alert action title?

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

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InvoiceItemTVC {

    var fetchedResultsController: NSFetchedResultsController<InvoiceItem> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = fetchBatchSize

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate
        if let parent = self.parentObject {
            let fetchPredicate = NSPredicate(format: "invoice == %@", parent)
            fetchRequest.predicate = fetchPredicate
        } else {
            print("\nPROBLEM - Unable able to add predicate")
        }

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

}

// MARK: - NSFetchedResultsControllerDelegate Extension
extension InvoiceItemTVC: NSFetchedResultsControllerDelegate {

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
