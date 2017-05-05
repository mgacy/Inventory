//
//  SettingsTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit

class SettingsTVC: UITableViewController, RootSectionViewController {

    // MARK: Properties
    var userManager: CurrentUserManager!
    var managedObjectContext: NSManagedObjectContext?

    // Segues
    let accountSegue = "showAccount"

    @IBOutlet weak var accountCell: UITableViewCell!

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
                fatalError("Wrong view controller type")
            }

            // Pass dependencies to the new view controller.
            destinationController.userManager = userManager

        default:
            break
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.verbose("Selected section \(indexPath.section)")

        // Account
        if indexPath.section == 0 {
            if let user = userManager.user {
                log.verbose("Logging out \(user.email)")

                /// TODO: check for pending Inventory / Invoice / Order
                /// TODO: if so, present warning

                userManager.logout(completion: completedLogout)
            } else {
                log.verbose("Showing AccountVC ...")
                performSegue(withIdentifier: accountSegue, sender: self)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    // MARK: - Configuration

    /// TODO: pass User?
    func configureAccountCell() {
        if let user = userManager.user {
            accountCell.textLabel?.text = "Logout \(user.email)"
        } else {
            accountCell.textLabel?.text = "Login"
        }
    }

}

// MARK: - Completion Handlers
extension SettingsTVC {

    func completedLogout(suceeded: Bool) {
        if suceeded {
            accountCell.textLabel?.text = "Login"
            deleteData()
        } else {
            log.warning("Unable to actually logout")
            accountCell.textLabel?.text = "Login"
            deleteData()
        }
    }

}

// MARK: - Delete Data
extension SettingsTVC {

    func deleteData() {
        guard let managedObjectContext = managedObjectContext else { return }

        /// TODO: use cascade rules to reduce list of entities we need to manually delete

        // Inventory
        do {
            try managedObjectContext.deleteEntities(Inventory.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete Inventories")
        }
        // Order
        do {
            try managedObjectContext.deleteEntities(OrderCollection.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete OrderCollections")
        }
        // Invoice
        do {
            try managedObjectContext.deleteEntities(InvoiceCollection.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete InvoiceCollections")
        }
        // Item
        do {
            try managedObjectContext.deleteEntities(Item.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete Items")
        }
        // ItemCategory
        do {
            try managedObjectContext.deleteEntities(ItemCategory.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete ItemCategories")
        }
        // Vendor
        do {
            try managedObjectContext.deleteEntities(Vendor.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete Vendors")
        }

        let result = managedObjectContext.saveOrRollback()
        print("Save result: \(result)")
    }

}
