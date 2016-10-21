//
//  InventoryLocationCategoryTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/9/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class InventoryLocationCategoryTVC: UITableViewController {
    
    // MARK: Properties
    var location: InventoryLocation!
    //var categories: [InventoryLocationCategory] {
    var categories: NSSet? {
        return location.categories
    }
    
    let CellIdentifier = "InventoryLocationCategoryTableViewCell"
    let ItemSegue = "ShowLocationItems2"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Set title.
        title = location.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
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
        return (categories?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as UITableViewCell
        /*
        // Get LocationCategory
        let category = categories[indexPath.row]
        
        // Configure the cell...
        if let name = category.name {
            cell.textLabel?.text = name
        }
        */
        return cell
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let selectedCategory = categories[indexPath.row]
        // print("Selected LocationCategory: \(selectedCategory)")
        
        performSegue(withIdentifier: ItemSegue, sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        if let destinationController = segue.destination as? InventoryLocationItemTVC {
            
            // Pass the selected object to the new view controller.
            guard let selectedIndex = self.tableView.indexPathForSelectedRow else {
                return
            }
            /*
            let selectedCategory = categories[selectedIndex.row]
            
            destinationController.category = selectedCategory
            destinationController.title = selectedCategory.name
            */
        }
    }
    
}
