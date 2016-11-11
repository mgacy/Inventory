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
    
    // Create a MessageComposer
    let messageComposer = MessageComposer()
    
    // TableView
    var cellIdentifier = "OrderItemTableViewCell"
    
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
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.performFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.performFetch()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User Interaction
    
    @IBAction func tappedMessageOrder(_ sender: UIBarButtonItem) {
        //guard let phoneNumber = parentObject.vendor.rep.phoneNumber else { return}
        guard let message = parentObject.getOrderMessage() else { return }
        print("\n\(message)")
        
        // Make sure the device can send text messages
        if (messageComposer.canSendText()) {

            // Obtain a configured MFMessageComposeViewController
            let messageComposeVC = messageComposer.configuredMessageComposeViewController(
                phoneNumber: "1-800-867-5309", message: message)
            
            // Present the configured MFMessageComposeViewController instance
            // Note that the dismissal of the VC will be handled by the messageComposer instance,
            // since it implements the appropriate delegate call-back
            present(messageComposeVC, animated: true, completion: nil)

        } else {
            
            // TODO - try to send email message?

            // Let the user know if his/her device isn't able to send text messages
            let errorAlert = createAlert(
                title: "Cannot Send Text Message",
                message: "Your device is not able to send text messages.",
                handler: nil)
            
            present(errorAlert, animated: true, completion: nil)
        }
    }

    // If we pass a handler, display a "Cancel" and an "OK" button with the latter calling that handler
    // Otherwise, display a single "OK" button
    // TODO - shouldn't we allow the specification of the okAction's title?
    // TODO - should we just present the alert within the function instead of returning it?
    func createAlert(title: String, message: String, handler: (() -> Void)? = nil) -> UIAlertController {
    
        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelTitle: String
        
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"
        
            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)
        
        case false:
            cancelTitle = "OK"
        }
        
        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        
        // Create alert controller
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelTitle: String
        switch handler != nil {
        case true:
            cancelTitle = "Cancel"
            
            // Create and add the OK action
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
                // Do some stuff
                handler!()
            }
            alert.addAction(okAction)
            
        case false:
            cancelTitle = "OK"
        }
        
        // Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Completion handlers
    
    func completedPlaceOrder(_ succeeded: Bool) {
        if succeeded {
            parentObject.placed = true
            
            // Serialize and POST Order
            if let json = parentObject.serialize() {
                print("\nPOSTing Order: \(json)")
                APIManager.sharedInstance.postOrder(order: json, completionHandler: completedPostOrder)
            }
        
            // TODO - handle failure to serialize Order
        
        } else {
            print("\nPROBLEM - Unable to send Order message")
            showAlert(title: "Problem", message: "Unable to send Order message")
        }
    }
        }

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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        
        // OLD
        //let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell
        
        // Configure Cell
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let orderItem = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = orderItem.item?.name
        
        guard let quantity = orderItem.quantity else { return }
        if Double(quantity) > 0.0 {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.text = "\(quantity) \(orderItem.orderUnit?.abbreviation ?? "")"
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            // TODO - should I even both displaying quantity?
            cell.detailTextLabel?.text = "\(quantity)"
        }
        // TODO - add warning color if quantity < suggested (excluding when par = 1 and suggested < 0.x)
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
        // TODO - sort by item.category.name as well?
        // let categorySortDescriptor = NSSortDescriptor(key: "item.category.name", ascending: true)
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
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
