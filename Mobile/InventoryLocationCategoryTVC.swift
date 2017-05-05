//
//  InventoryLocationCategoryTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryLocationCategoryTVC: UITableViewController, SegueHandler {

    // MARK: Properties

    var location: InventoryLocation!
    var selectedCategory: InventoryLocationCategory?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //let filter: NSPredicate? = nil
    //let cacheName: String? = nil // "Master"
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryLocationCategoryTableViewCell"

    // Segues
    enum SegueIdentifier: String {
        case showItem = "ShowLocationItems2"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = location.name
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
        guard let destinationController = segue.destination as? InventoryLocationItemTVC else { fatalError("Wrong view controller type") }
        guard let selection = selectedCategory else { fatalError("Showing detail, but no selected row?") }

        // Pass the selected object to the new view controller.
        destinationController.title = selection.name
        destinationController.category = selection
        destinationController.managedObjectContext = managedObjectContext
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationCategoryTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InventoryLocationCategory> = InventoryLocationCategory.fetchRequest()
        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        // Set the fetch predicate.
        let fetchPredicate = NSPredicate(format: "location == %@", location)
        request.predicate = fetchPredicate

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = dataSource.objectAtIndexPath(indexPath)
        performSegue(withIdentifier: .showItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationCategoryTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for locationCategory: InventoryLocationCategory) {
        cell.textLabel?.text = locationCategory.name

        switch locationCategory.status {
        case .notStarted:
            cell.textLabel?.textColor = UIColor.lightGray
        case .incomplete:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case .complete:
            cell.textLabel?.textColor = UIColor.black
        }
    }

}
