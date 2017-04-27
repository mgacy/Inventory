//
//  InvoiceVendorTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InvoiceVendorTVC: UITableViewController {

    // MARK: - Properties

    var parentObject: InvoiceCollection!
    var selectedObject: Invoice?

    // MARK: FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    var _fetchedResultsController: NSFetchedResultsController<Invoice>? = nil
    var filter: NSPredicate? = nil
    var cacheName: String? = "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showInvoiceItems"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // Set Title
        title = "Vendors"

        // Register reusable cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

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
        guard let destinationController = segue.destination as? InvoiceItemTVC else {
            fatalError("Wrong view controller type")
        }
        guard let selectedObject = selectedObject else {
            fatalError("Showing detail, but no selected row?")
        }

        // Pass the selected object to the new view controller.
        destinationController.parentObject = selectedObject
        destinationController.managedObjectContext = managedObjectContext
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let invoice = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = invoice.vendor?.name

        switch invoice.uploaded {
        case false:
            //cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case true:
            cell.textLabel?.textColor = UIColor.black
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = self.fetchedResultsController.object(at: indexPath)
        log.verbose("Selected Invoice: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InvoiceVendorTVC {

    var fetchedResultsController: NSFetchedResultsController<Invoice> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<Invoice> = Invoice.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = fetchBatchSize

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "vendor.name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate
        let fetchPredicate = NSPredicate(format: "collection == %@", parentObject)
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
extension InvoiceVendorTVC: NSFetchedResultsControllerDelegate {

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
