//
//  InventoryLocationItemTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class InventoryLocationItemTVC: UITableViewController {
    
    // MARK: Properties
    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    //var items: [InventoryLocationItem] {
    var items: NSSet? {
        if let category = category {
            return category.items
        } else if let location = location {
            return location.items
        } else {
            //return [InventoryLocationItem]()
            return nil
        }
    }
    var selectedItem: InventoryLocationItem?
    
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items!.count
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
            print("PROBLEM configuringCell")
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
        // let selectedItem = items[indexPath.row]
        // print("Selected LocationItem: \(selectedItem)")
        
        performSegue(withIdentifier: KeypadSegue, sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        if let destinationController = segue.destination as? InventoryKeypadVC {
            
            // Pass the parent of the selected object to the new view controller.
            // TODO: should I really pass both or just the one != nil?
            destinationController.category = category
            destinationController.location = location
            
            if let indexPath = self.tableView.indexPathForSelectedRow?.row {
                destinationController.currentIndex = indexPath
            }
        }
    }
    
}
