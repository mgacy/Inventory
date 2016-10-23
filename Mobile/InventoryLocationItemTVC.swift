//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryLocationItemTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Properties
    
    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    var selectedItem: InventoryLocationItem?
    
    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext? = nil
    //var filter: NSPredicate? = nil
    var cacheName: String? = nil
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit
    
    // TableViewCell
    let cellIdentifier = "InventoryLocationTableViewCell"
    
    // Segues
    let KeypadSegue = "ShowInventoryKeypad"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Register reusable cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // CoreData
        performFetch()
        //let objects = self.fetchedResultsController.fetchedObjects
        //print("Fetched Objects: \(objects)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
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
        
        // Configure the cell
        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let locationItem = self.fetchedResultsController.object(at: indexPath)
        
        // TEMP
        //cell.textLabel?.text = "Item \(locationItem.quantity)"
        //cell.textLabel?.text = "Item \(locationItem.itemID)"
        
        if let item = locationItem.item {
            cell.textLabel?.text = item.name
        } else {
            print("\nPROBLEM - configuringCell\n")
        }
    }
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    // Override to support editing the table view.
    // override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    // Override to support rearranging the table view.
    // override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {}
    
    // Override to support conditional rearranging of the table view.
    // override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {}
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem = self.fetchedResultsController.object(at: indexPath)
        // print("Selected LocationItem: \(selectedItem)")
        
        performSegue(withIdentifier: KeypadSegue, sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        guard let destinationController = segue.destination as? InventoryKeypadVC else {
            return
        }
        
        // Pass the parent of the selected object to the new view controller.
        // TODO: should I really pass both or just the one != nil?
        destinationController.category = category
        destinationController.location = location
        
        // FIX: fix this
        if let indexPath = self.tableView.indexPathForSelectedRow?.row {
            destinationController.currentIndex = indexPath
        }
    
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<InventoryLocationItem> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = self.fetchBatchSize
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Set the fetch predicate.
        if let parentLocation = self.location {
            let fetchPredicate = NSPredicate(format: "location == %@", parentLocation)
            print("\nAdding predicate \(fetchPredicate)")
            fetchRequest.predicate = fetchPredicate
            
        } else if let parentCategory = self.category {
            let fetchPredicate = NSPredicate(format: "category == %@", parentCategory)
            print("\nAdding predicate \(fetchPredicate)")
            fetchRequest.predicate = fetchPredicate

        } else {
            print("\nPROBLEM - Unable to add predicate\n")
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
            
            // TESTING:
            let objects = self.fetchedResultsController.fetchedObjects
            print("Fetched Objects: \(objects?.count)")
            if let expectedLocations = self.fetchedResultsController.fetchedObjects {
                print("Item TVC should display: \(expectedLocations)")
            }
            
            self.tableView.reloadData()
        })
    }
    
    var _fetchedResultsController: NSFetchedResultsController<InventoryLocationItem>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
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
            self.configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
}
