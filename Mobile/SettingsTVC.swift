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

        // Inventory
        do {
            try managedObjectContext.deleteEntities(Inventory.self)
        } catch {
            print("Unable to delete Inventories")
        }
        // Order
        do {
            try managedObjectContext.deleteEntities(OrderCollection.self)
        } catch {
            print("Unable to delete OrderCollections")
        }
        // Invoice
        do {
            try managedObjectContext.deleteEntities(InvoiceCollection.self)
        } catch {
            print("Unable to delete InvoiceCollections")
        }
        // Item
        do {
            try managedObjectContext.deleteEntities(Item.self)
        } catch {
            print("Unable to delete Items")
        }
    }

}
