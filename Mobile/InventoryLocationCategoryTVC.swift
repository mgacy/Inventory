//
//  InventoryLocationCategoryTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryLocationCategoryTVC: UITableViewController {

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
    let ItemSegue = "ShowLocationItems2"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = location.name
        setupTableView()
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
        guard let destinationController = segue.destination as? InventoryLocationItemTVC else { fatalError("Wrong view controller type") }
        guard let selection = selectedCategory else { fatalError("Showing detail, but no selected row?") }

        // Pass the selected object to the new view controller.
        destinationController.title = selection.name
        destinationController.category = selection
        destinationController.managedObjectContext = self.managedObjectContext
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
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        if let parent = self.location {
            let fetchPredicate = NSPredicate(format: "location == %@", parent)
            request.predicate = fetchPredicate
        } else {
            print("\(#function) FAILED : unable to add predicate")
        }

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = dataSource.objectAtIndexPath(indexPath)
        // print("Selected LocationCategory: \(selectedCategory)")

        performSegue(withIdentifier: ItemSegue, sender: self)

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
