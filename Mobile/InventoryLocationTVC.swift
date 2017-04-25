//
//  InventoryLocationTVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import PKHUD

class InventoryLocationTVC: UITableViewController {

    // MARK: - Properties

    /* Force unwrap (`!`) because:
     (a) a variable must have an initial value
     (b) while we could use `?`, we would then have to unwrap it whenever we access it
     (c) using a forced unwrapped optional is safe since this controller won't work without a value
     */
    var inventory: Inventory!
    var selectedLocation: InventoryLocation?

    // FetchedResultsController
    var managedObjectContext: NSManagedObjectContext?
    //let filter: NSPredicate? = nil
    //let cacheName: String? = nil // "Master"
    //let objectsAsFaults = false
    let fetchBatchSize = 20 // 0 = No Limit

    // TableViewCell
    let cellIdentifier = "InventoryLocationTableViewCell"

    // Segues
    let CategorySegue = "ShowLocationCategory"
    let ItemSegue = "ShowLocationItem"
    /*
    enum SegueIdentifiers : String {
        case categorySegue = "ShowLocationCategory"
        case itemSegue = "ShowLocationItem"
    }
    */
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Locations"
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

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Get the selected object.
        guard let selection = selectedLocation else { fatalError("Showing detail, but no selected row?") }

        switch segue.identifier! {
        case CategorySegue:
            guard let destinationController = segue.destination as? InventoryLocationCategoryTVC else { fatalError("Wrong view controller type") }

            // Pass the selected object to the new view controller.
            destinationController.location = selection
            destinationController.managedObjectContext = self.managedObjectContext
            //destinationController.performFetch()

        case ItemSegue:
            guard let destinationController = segue.destination as? InventoryLocationItemTVC else { fatalError("Wrong view controller type") }

            // Pass the selected object to the new view controller.
            destinationController.title = selection.name
            destinationController.location = selection
            destinationController.managedObjectContext = self.managedObjectContext
            //destinationController.performFetch()

        default:
            print("\(#function) FAILED : segue.identifier not recognized\n"); break
        }
    }

    // MARK: - TableViewDataSource
    fileprivate var dataSource: TableViewDataSource<InventoryLocationTVC>!
    //fileprivate var observer: ManagedObjectObserver?

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        //tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = 100

        //let request = Mood.sortedFetchRequest(with: moodSource.predicate)
        let request: NSFetchRequest<InventoryLocation> = InventoryLocation.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        // Set the fetch predicate.
        if let parent = self.inventory {
            let fetchPredicate = NSPredicate(format: "inventory == %@", parent)
            request.predicate = fetchPredicate
        } else {
            print("\(#function) FAILED : unable able to add predicate\n")
        }

        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)

        dataSource = TableViewDataSource(tableView: tableView, cellIdentifier: cellIdentifier, fetchedResultsController: frc, delegate: self)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLocation = dataSource.objectAtIndexPath(indexPath)

        // Perform segue based on locationType of selected Inventory.
        switch selectedLocation!.locationType {
        case "category"?:
            //  InventoryLocationCategory
            performSegue(withIdentifier: "ShowLocationCategory", sender: self)
        case "item"?:
            // InventoryLocationItem
            performSegue(withIdentifier: "ShowLocationItem", sender: self)
        default:
            print("\(#function) FAILED : wrong locationType\n")
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @IBAction func uploadTapped(_ sender: AnyObject) {
        print("Uploading Inventory ...")
        HUD.show(.progress)

        guard let dict = self.inventory.serialize() else {
            print("\(#function) FAILED : unable to serialize Inventory")
            // TODO - completedUpload(false)
            return
        }
        APIManager.sharedInstance.postInventory(inventory: dict, completion: self.completedUpload)
    }

}

// MARK: - Completion Handlers
extension InventoryLocationTVC {

    func completedUpload(json: JSON?, error: Error?) {
        guard error == nil else {
            HUD.flash(.error, delay: 1.0); return
        }
        guard let json = json else {
            print("\(#function) FAILED: unable to get JSON")
            HUD.flash(.error, delay: 1.0); return
        }
        guard let remoteID = json["id"].int else {
            print("\(#function) FAILED: unable to get remoteID of posted Inventory")
            HUD.flash(.error, delay: 1.0); return
        }

        inventory.uploaded = true
        inventory.remoteID = Int32(remoteID)

        HUD.flash(.success, delay: 1.0)

        // Pop view
        navigationController!.popViewController(animated: true)
    }

}


// MARK: - TableViewDataSourceDelegate Extension
extension InventoryLocationTVC: TableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for location: InventoryLocation) {
        cell.textLabel?.text = location.name

        if let status = location.status {
            switch status {
            case .notStarted:
                cell.textLabel?.textColor = UIColor.lightGray
            case .incomplete:
                cell.textLabel?.textColor = ColorPalette.yellowColor
            case .complete:
                cell.textLabel?.textColor = UIColor.black
            }
        }
    }
    
}
