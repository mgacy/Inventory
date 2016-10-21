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
    
    // MARK: New
    var managedObjectContext: NSManagedObjectContext? = nil
    
    
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
    

    // Computed property (using getter)
    var locations: NSSet {
        print("locations.getter - \(inventory)")
        if let locations = inventory?.locations {
            return locations
        } else {
            return NSSet()
        }
    }

    
    let CellIdentifier = "InventoryLocationTableViewCell"
    // let CategorySegue = "ShowLocationCategory"
    // let ItemSegue = "ShowLocationItem"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Set Title
        title = "Locations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        
        // Get CoreData stuff
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as UITableViewCell
        
        // Fetch the appropriate Location for the data source layout.
        //let location = locations[indexPath.row]
        let location = self.fetchedResultsController.object(at: indexPath)
        
        // Configure the cell...
        self.configureCell(cell, withObject: location)
        
        return cell
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {}
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {}
     */
    
    
    // Override to support conditional editing of the table view.
    // override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {}
    
    func configureCell(_ cell: UITableViewCell, withObject object: InventoryLocation) {
        cell.textLabel?.text = object.name
    }
    
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
            print("PROBLEM - Wrong locationType")
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
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchRequest.predicate = NSPredicate(format: ".inventory == \(inventory)")
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        /*
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        */
 
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
            self.configureCell(tableView.cellForRow(at: indexPath!)!, withObject: anObject as! InventoryLocation)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
}

