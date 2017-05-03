//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryLocationItemTVC: UITableViewController, SegueHandler {

    // MARK: Properties

    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    var selectedItem: InventoryLocationItem?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    //let filter: NSPredicate? = nil
    //let cacheName: String? = nil
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    //let cellIdentifier = "InventoryLocationTableViewCell"
    let cellIdentifier = "InventoryItemCell"

    // Segues
     enum SegueIdentifier : String {
        case showKeypad = "ShowInventoryKeypad"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
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
        guard let destinationController = segue.destination as? InventoryKeypadVC else { fatalError("Wrong view controller type") }

        // Pass the parent of the selected object to the new view controller.
        // TODO: should I really pass both or just the one != nil?
        destinationController.category = category
        destinationController.location = location
        destinationController.managedObjectContext = self.managedObjectContext

        // FIX: fix this
        if let indexPath = self.tableView.indexPathForSelectedRow?.row {
            destinationController.currentIndex = indexPath
        }
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationItemTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()

        // Edit the sort key as appropriate.
        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        // Set the fetch predicate.
        if let parentLocation = self.location {
            let fetchPredicate = NSPredicate(format: "location == %@", parentLocation)
            request.predicate = fetchPredicate

        } else if let parentCategory = self.category {
            let fetchPredicate = NSPredicate(format: "category == %@", parentCategory)
            request.predicate = fetchPredicate

        } else {
            fatalError("Unable to add predicate")
        }

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = dataSource.objectAtIndexPath(indexPath)
        performSegue(withIdentifier: .showKeypad)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationItemTVC: TableViewDataSourceDelegate {
    func configure(_ cell: InventoryItemTableViewCell, for locationItem: InventoryLocationItem) {
        cell.configure(for: locationItem)
    }
}
