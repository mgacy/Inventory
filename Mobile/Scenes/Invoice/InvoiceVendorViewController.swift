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
    private enum Strings {
        static let navTitle = "Vendors"
        static let errorAlertTitle = "Error"
    }

    var parentObject: InvoiceCollection!

    // MARK: FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate? = nil
    //var cacheName: String? = "Master"
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "Cell"


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    //override func didReceiveMemoryWarning() {}

    // MARK: - View Methods

    private func setupView() {
        title = Strings.navTitle
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InvoiceVendorViewController>!

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

    // MARK: - Navigation

    fileprivate func showInvoice(withInvoice invoice: Invoice) {
        let vc = InvoiceItemViewController.initFromStoryboard(name: "Main")
        vc.parentObject = invoice
        vc.managedObjectContext = managedObjectContext
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected Invoice: \(selectedObject)")
        showInvoice(withInvoice: selectedObject)
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
