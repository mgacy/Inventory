//
//  OrderVendorTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class OrderVendorTVC: UITableViewController {
    // MARK: - Properties

    var parentObject: OrderCollection!
    var selectedObject: Order?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //var filter: NSPredicate? = nil
    //var cacheName: String? = nil
    //var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableView
     var cellIdentifier = "Cell"

    // Segues
    let segueIdentifier = "showOrderItems"

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationController = segue.destination as? OrderItemTVC else {
            fatalError("Wrong view controller type")
        }
        guard let selectedObject = selectedObject else {
            fatalError("Showing detail, but no selected row?")
        }

        // Pass the selected object to the new view controller.
        destinationController.parentObject = selectedObject
        destinationController.managedObjectContext = self.managedObjectContext
    }

    // MARK: - UITableViewDataSource

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderVendorTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<Order> = Order.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "vendor.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate
        let fetchPredicate = NSPredicate(format: "collection == %@", parentObject)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = dataSource.objectAtIndexPath(indexPath)
        log.verbose("Selected Order: \(selectedObject)")

        performSegue(withIdentifier: segueIdentifier, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderVendorTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for order: Order) {
        cell.textLabel?.text = order.vendor?.name

        /// TODO: handle situation where user placed an order but uploading to the server failed;
        // we still need to make sure that it ends up getting uploaded

        switch order.placed {
        case false:
            //cell.textLabel?.textColor = UIColor.lightGray
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case true:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
