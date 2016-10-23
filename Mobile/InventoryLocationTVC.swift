//
//  InventoryLocationTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryLocationTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Properties
    
    /* Force unwrap (`!`) because:
     (a) a variable must have an initial value
     (b) while we could use `?`, we would then have to unwrap it whenever we access it
     (c) using a forced unwrapped optional is safe since this controller won't work without a value
     */
    var inventory: Inventory!
//    var locations = [InventoryLocation]()
//    var locations: [InventoryLocation] {
//        
//    }
    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    

    // Computed property (using getter)
    var locations: NSSet {
        print("locations.getter - \(inventory)")
        if let locations = inventory?.locations {
            return locations
        } else {
            return NSSet()
        }
    }

    // TableViewCell
    let cellIdentifier = "InventoryLocationTableViewCell"
    
    // Segues
    let CategorySegue = "ShowLocationCategory"
    let ItemSegue = "ShowLocationItem"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Set Title
        title = "Locations"
        
        // Register reusable cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        // CoreData
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //return 1
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return locations.count
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
        let location = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = location.name
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
        
        guard let selectedIndex = self.tableView.indexPathForSelectedRow else {
            return
        }
        
        //let selectedLocation = locations[selectedIndex.row]
        let selectedLocation = self.fetchedResultsController.object(at: selectedIndex)
        
        
        if segue.identifier == "ShowLocationCategory" {
            
            // Get the new view controller using segue.destinationViewController.
            if let destinationController = segue.destination as? InventoryLocationCategoryTVC {
                
                // Pass the selected object to the new view controller.
                destinationController.location = selectedLocation
            }
            
        } else if segue.identifier == "ShowLocationItem" {
            
            // Get the new view controller using segue.destinationViewController.
            if let destinationController = segue.destination as? InventoryLocationItemTVC {
                
                // Pass the selected object to the new view controller.
                destinationController.location = selectedLocation
                destinationController.title = selectedLocation.name
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let selectedLocation = locations[indexPath.row]
        let selectedLocation = self.fetchedResultsController.object(at: indexPath)
        
        /*
        // Perform segue based on locationType of selected Inventory.
        switch selectedLocation.locationType {
        case "category"?:
            //  InventoryLocationCategory
            performSegue(withIdentifier: "ShowLocationCategory", sender: self)
        case "item"?:
            // InventoryLocationItem
            performSegue(withIdentifier: "ShowLocationItem", sender: self)
        default:
            print("\nPROBLEM - Wrong locationType\n")
        }
        */
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<InventoryLocation> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchRequest.predicate = NSPredicate(format: ".inventory == \(inventory)")
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
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
    
    var _fetchedResultsController: NSFetchedResultsController<InventoryLocation>? = nil
    
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

