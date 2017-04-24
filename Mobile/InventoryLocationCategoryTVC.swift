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
    var _fetchedResultsController: NSFetchedResultsController<InventoryLocationCategory>? = nil
    //var filter: NSPredicate? = nil
    var cacheName: String? = nil // "Master"
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryLocationCategoryTableViewCell"

    // Segues
    let ItemSegue = "ShowLocationItems2"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // Set title.
        title = location.name

        // Register reusable cell.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        // CoreData
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
        guard let destinationController = segue.destination as? InventoryLocationItemTVC else { fatalError("Wrong view controller type") }
        guard let selection = selectedCategory else { fatalError("Showing detail, but no selected row?") }

        // Pass the selected object to the new view controller.
        destinationController.title = selection.name
        destinationController.category = selection
        destinationController.managedObjectContext = self.managedObjectContext
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell

        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let category = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = category.name

        switch category.status {
        case .notStarted:
            cell.textLabel?.textColor = UIColor.lightGray
        case .incomplete:
            cell.textLabel?.textColor = ColorPalette.yellowColor
        case .complete:
            cell.textLabel?.textColor = UIColor.black
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = self.fetchedResultsController.object(at: indexPath)
        // print("Selected LocationCategory: \(selectedCategory)")

        performSegue(withIdentifier: ItemSegue, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - Type-Specific NSFetchedResultsController Extension
extension InventoryLocationCategoryTVC {

    var fetchedResultsController: NSFetchedResultsController<InventoryLocationCategory> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest: NSFetchRequest<InventoryLocationCategory> = InventoryLocationCategory.fetchRequest()

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = self.fetchBatchSize

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        if let parent = self.location {
            let fetchPredicate = NSPredicate(format: "location == %@", parent)
            fetchRequest.predicate = fetchPredicate
        } else {
            print("\(#function) FAILED : unable to add predicate")
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
extension InventoryLocationCategoryTVC: NSFetchedResultsControllerDelegate {

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
