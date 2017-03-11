//
//  SettingsTVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController {

    // MARK: Properties
    let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager

    // Segues
    let accountSegue = "showAccount"

    @IBOutlet weak var AccountCell: UITableViewCell!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        title = "Settings"
        configureAccountCell()
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
            // let destinationController = segue.destination as! AccountVC
            // destinationController.readFromKeychain()
            break
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

                APIManager.sharedInstance.logout(completion: completedLogout)
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
            userManager.removeUser()
            AccountCell.textLabel?.text = "Login"
        } else {
            print("Nope")
            // TEMP
            userManager.removeUser()
            AccountCell.textLabel?.text = "Login"
        }
    }

}
