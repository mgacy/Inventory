//
//  OrderItemTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class OrderItemTVC: UITableViewController, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    
    var parentObject: Order!
    var selectedObject: OrderItem?
    
    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    var filter: NSPredicate? = nil
    var cacheName: String? = nil
    var sectionNameKeyPath: String? = nil
    var fetchBatchSize = 20 // 0 = No Limit
    
    // TableView
    var cellIdentifier = "Cell"
    
    // Segues
    let segueIdentifier = "showOrderKeypad"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Set Title
        title = parentObject.vendorName
        
        // Register reusable cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.performFetch()
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
        
        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let orderItem = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = orderItem.itemName
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedObject = self.fetchedResultsController.object(at: indexPath)
        // print("Selected OrderItem: \(selectedObject)")
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
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
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        guard let destinationController = segue.destination as? OrderKeypadVC else {
            return
        }
        
        // Pass the parent of the selected object to the new view controller.
        destinationController.parentObject = parentObject
        destinationController.managedObjectContext = self.managedObjectContext
        
        // FIX: fix this
        if let indexPath = self.tableView.indexPathForSelectedRow?.row {
            destinationController.currentIndex = indexPath
        }

    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<OrderItem> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = fetchBatchSize
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "itemName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Set the fetch predicate
        if let parent = self.parentObject {
            let fetchPredicate = NSPredicate(format: "order == %@", parent)
            fetchRequest.predicate = fetchPredicate
        } else {
            print("\nPROBLEM - Unable able to add predicate")
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
    
    var _fetchedResultsController: NSFetchedResultsController<OrderItem>? = nil
    
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
                print("OrderItemTVC should display: \(expectedLocations)")
            }
            
            self.tableView.reloadData()
        })
    }
    
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
