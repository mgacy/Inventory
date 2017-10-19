//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

enum LocationItemListParent {
    case category(InventoryLocationCategory)
    case location(InventoryLocation)
    // This case allows us to set default value on classes w/o initializer
    case none

    var fetchPredicate: NSPredicate? {
        switch self {
        case .category(let category):
            return NSPredicate(format: "category == %@", category)
        case .location(let location):
            return NSPredicate(format: "location == %@", location)
        case .none:
            return nil
        }
    }

}

class InventoryLocationItemTVC: UITableViewController {

    // MARK: Properties

    var parentObject: LocationItemListParent = .none

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //let filter: NSPredicate? = nil
    //let cacheName: String? = nil
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryItemCell"

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

    fileprivate func showKeypad(withItem item: InventoryLocationItem) {
        guard let destinationController = InventoryKeypadViewController.instance() else {
            fatalError("\(#function) FAILED: unable to get destination view controller.")
        }
        guard
            let indexPath = self.tableView.indexPathForSelectedRow?.row,
            let managedObjectContext = managedObjectContext else {
                fatalError("\(#function) FAILED: unable to get indexPath or moc")
        }

        destinationController.parentObject = parentObject
        destinationController.currentIndex = indexPath
        destinationController.managedObjectContext = managedObjectContext

        navigationController?.pushViewController(destinationController, animated: true)
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationItemTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(SubItemTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80

        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()

        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        //request.predicate = parentObject.fetchPredicate
        switch self.parentObject {
        case .category(let parentCategory):
            request.predicate = NSPredicate(format: "category == %@", parentCategory)
        case .location(let parentLocation):
            request.predicate = NSPredicate(format: "location == %@", parentLocation)
        case .none:
            fatalError("\(#function) FAILED : parentObject not set")
        }

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier,
                                         fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = dataSource.objectAtIndexPath(indexPath)
        showKeypad(withItem: selectedItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationItemTVC: TableViewDataSourceDelegate {
    func configure(_ cell: SubItemTableViewCell, for locationItem: InventoryLocationItem) {
        let viewModel = InventoryLocationItemViewModel(forLocationItem: locationItem)
        cell.configure(withViewModel: viewModel)
    }
}
