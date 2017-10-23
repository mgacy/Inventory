//
//  InvoiceVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InvoiceVendorViewController: UITableViewController {

    // MARK: - Properties

    var parentObject: InvoiceCollection!
    var selectedObject: Invoice?

    // MARK: FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate? = nil
    //var cacheName: String? = "Master"
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showInvoiceItems"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vendors"
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationController = segue.destination as? InvoiceItemViewController else {
            fatalError("Wrong view controller type")
        }
        guard let selectedObject = selectedObject else {
            fatalError("Showing detail, but no selected row?")
        }
        destinationController.parentObject = selectedObject
        destinationController.managedObjectContext = managedObjectContext
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "vendor.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        let fetchPredicate = NSPredicate(format: "collection == %@", parentObject)
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
        log.verbose("Selected Invoice: \(String(describing: selectedObject))")

        performSegue(withIdentifier: segueIdentifier, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InvoiceVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for invoice: Invoice) {
       cell.textLabel?.text = invoice.vendor?.name

        switch invoice.uploaded {
        case false:
            //cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case true:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
