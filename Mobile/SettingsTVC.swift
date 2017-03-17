//
//  SettingsTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit

class SettingsTVC: UITableViewController {

    // MARK: Properties
    let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager

    var managedObjectContext: NSManagedObjectContext? = nil

    // Segues
    let accountSegue = "showAccount"

    @IBOutlet weak var AccountCell: UITableViewCell!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        title = "Settings"
        configureAccountCell()

        // CoreData
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewWillAppear(_ animated: Bool) {
        configureAccountCell()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case accountSegue:

            // Get the new view controller.
            guard
                let destinationNavController = segue.destination as? UINavigationController,
                let destinationController = destinationNavController.topViewController as? LoginVC
            else {
                debugPrint("\(#function) FAILED : unable to get destination"); return
            }

            // Pass dependencies to the new view controller.
            destinationController.userManager = userManager

        default:
            break
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected section \(indexPath.section)")

        // Account
        if indexPath.section == 0 {
            if let user = userManager.user {
                print("Logging out \(user.email)")

                // TODO - check for pending Inventory / Invoice / Order
                // TODO - if so, present warning

                userManager.logout(completion: completedLogout)
            } else {
                print("Showing AccountVC ...")
                performSegue(withIdentifier: accountSegue, sender: self)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    // MARK: - Configuration

    // TODO - pass User?
    func configureAccountCell() {
        if let user = userManager.user {
            AccountCell.textLabel?.text = "Logout \(user.email)"
        } else {
            AccountCell.textLabel?.text = "Login"
        }
    }

}

// MARK: - Completion Handlers
extension SettingsTVC {

    func completedLogout(suceeded: Bool) {
        if suceeded {
            AccountCell.textLabel?.text = "Login"
            deleteData()
        } else {
            print("Unable to actually logout")
            AccountCell.textLabel?.text = "Login"
            deleteData()
        }
    }

}

// MARK: - Delete Data
extension SettingsTVC {

    func deleteData() {
        guard let managedObjectContext = managedObjectContext else { return }

        /*
         Since the batch delete request directly interacts with the persistent store we need
         to make sure that any changes are first pushed to that store.
         */
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
        }

        //var batchDeleteRequest:
        //var batchDeleteResult:

        // MARK: Inventory

        // Create Fetch Request (Inventory)
        let inventoryFetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()

        // Initialize and configure Batch Delete Request
        var batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: inventoryFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            //try managedObjectContext.execute(batchDeleteRequest)
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Invoice

        // Create Fetch Request (Invoice)
        let invoiceFetchRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: invoiceFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Order

        // Create Fetch Request (Order)
        let orderFetchRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: orderFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Item

        // Create Fetch Request (Item)
        let itemFetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: itemFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")

            // The managed object context is not notified of the consequences of the batch delete request.

            // Reset Managed Object Context
            // As the request directly interacts with the persistent store, we need need to reset the context
            // for it to be aware of the changes
            managedObjectContext.reset()
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}

/*
extension SettingsTVC {

    func deleteDataOld() {
        guard let managedObjectContext = managedObjectContext else {
            return
        }

        /*
         Since the batch delete request directly interacts with the persistent store we need
         to make sure that any changes are first pushed to that store.
         */
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
        }

        //var batchDeleteRequest:
        //var batchDeleteResult:

        // MARK: Inventory

        // Create Fetch Request (Inventory)
        let inventoryFetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()

        // Initialize and configure Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: inventoryFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Invoice

        // Create Fetch Request (Invoice)
        let invoiceFetchRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()

        // Initialize and configure Batch Delete Request
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: invoiceFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest2.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult2 = try managedObjectContext.execute(batchDeleteRequest2) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult2.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Order

        // Create Fetch Request (Order)
        let orderFetchRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()

        // Initialize and configure Batch Delete Request
        let batchDeleteRequest3 = NSBatchDeleteRequest(fetchRequest: orderFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest3.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult3 = try managedObjectContext.execute(batchDeleteRequest3) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult3.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }

        // MARK: Item

        // Create Fetch Request (Item)
        let itemFetchRequest: NSFetchRequest<Item> = Item.fetchRequest()

        // Initialize and configure Batch Delete Request
        let batchDeleteRequest4 = NSBatchDeleteRequest(fetchRequest: itemFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest4.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult4 = try managedObjectContext.execute(batchDeleteRequest4) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult4.result!) records.")

            // The managed object context is not notified of the consequences of the batch delete request.

            // Reset Managed Object Context
            // As the request directly interacts with the persistent store, we need need to reset the context
            // for it to be aware of the changes
            managedObjectContext.reset()
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}
*/

/*
extension SettingsTVC {

    func deleteData3() {
        guard let managedObjectContext = managedObjectContext else { return }

        /*
         Since the batch delete request directly interacts with the persistent store we need
         to make sure that any changes are first pushed to that store.
         */
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let saveError = error as NSError
                print("\(saveError), \(saveError.userInfo)")
            }
        }

        // Create Fetch Request (Inventory)
        let inventoryFetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        executeBatchDelete(forRequest: inventoryFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Create Fetch Request (Invoice)
        let invoiceFetchRequest: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        executeBatchDelete(forRequest: invoiceFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Create Fetch Request (Order)
        let orderFetchRequest: NSFetchRequest<OrderCollection> = OrderCollection.fetchRequest()
        executeBatchDelete(forRequest: orderFetchRequest as! NSFetchRequest<NSFetchRequestResult>)

        // Create Fetch Request (Item)
        let itemFetchRequest: NSFetchRequest<Item> = Item.fetchRequest()

        // Initialize / configure batch delete request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: itemFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeCount

        do {
            // Execute Batch Request
            let batchDeleteResult = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")

            // The managed object context is not notified of the consequences of the batch delete request.

            // Reset Managed Object Context
            // As the request directly interacts with the persistent store, we need need to reset the context
            // for it to be aware of the changes
            managedObjectContext.reset()

        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

    func executeBatchDelete(forRequest request: NSFetchRequest<NSFetchRequestResult>) {
        guard let managedObjectContext = managedObjectContext else {
            return
        }

        // Initialize / configure batch delete request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchDeleteRequest.resultType = .resultTypeCount

        // Execute batch request
        do {
            let batchDeleteResult = try managedObjectContext.execute(request) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}
*/
