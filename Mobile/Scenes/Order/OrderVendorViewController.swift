//
//  OrderVendorViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class OrderVendorViewController: UITableViewController {
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vendors"
        setupTableView()

        let completeButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "DoneBarButton"), style: .done, target: self,
                                                 action: #selector(tappedCompleteOrders))
        navigationItem.rightBarButtonItem = completeButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        parentObject.updateStatus()
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    private func showOrderItemView(withOrder order: Order) {
        guard let destinationController = OrderItemViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        destinationController.viewModel = OrderViewModel(forOrder: order)
        destinationController.parentObject = order
        destinationController.managedObjectContext = self.managedObjectContext
        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - UITableViewDataSource

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<OrderVendorViewController>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<Order> = Order.fetchRequest()
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
        log.verbose("Selected Order: \(String(describing: selectedObject))")

        //performSegue(withIdentifier: segueIdentifier, sender: self)
        guard let selection = selectedObject else {
            fatalError("Couldn't get selected Order")
        }
        showOrderItemView(withOrder: selection)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension OrderVendorViewController: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for order: Order) {
        cell.textLabel?.text = order.vendor?.name

        /// TODO: handle situation where user placed an order but uploading to the server failed;
        // we still need to make sure that it ends up getting uploaded

        switch order.status {
        case OrderStatus.incomplete.rawValue:
            cell.textLabel?.textColor = ColorPalette.redColor
        case OrderStatus.empty.rawValue:
            cell.textLabel?.textColor = UIColor.lightGray
        case OrderStatus.pending.rawValue:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case OrderStatus.placed.rawValue:
            /// TODO: use another color?
            cell.textLabel?.textColor = UIColor.black
        case OrderStatus.uploaded.rawValue:
            cell.textLabel?.textColor = UIColor.black
        default:
            /// TODO: use another color for values that aren't captured above
            cell.textLabel?.textColor = UIColor.black
        }
    }

}

// MARK: - User Actions
extension OrderVendorViewController {

    func tappedCompleteOrders() {
        // If there are pending orders we want to warn the user about marking this collection as completed
        guard checkStatusIsSafe() else {
            let errorAlert = createAlert(title: "Warning: Pending Orders",
                                         message: "Marking order collection as completed will delete any pending " +
                                                  "orders. Are you sure you want to proceed?",
                                         handler: completeOrders)
            present(errorAlert, animated: true, completion: nil)
            return
        }
        completeOrders()
    }

    func checkStatusIsSafe() -> Bool {
        guard let orders = parentObject.orders else {
            return true
        }

        //var hasEmpty = false
        var hasPending = false

        for order in orders {
            if let status = (order as? Order)?.status {
                switch status {
                //case OrderStatus.empty.rawValue:
                //    hasEmpty = true
                case OrderStatus.pending.rawValue:
                    hasPending = true
                //case OrderStatus.placed.rawValue:
                //case OrderStatus.uploaded.rawValue:
                default:
                    /// TODO: use another color for values that aren't captured above
                    continue
                }
            }
        }

        if hasPending {
            return false
        } else {
            return true
        }
    }

    func completeOrders() {
        parentObject.uploaded = true
        /// TODO: refresh OrderDateViewController
        self.navigationController!.popViewController(animated: true)
    }

}
