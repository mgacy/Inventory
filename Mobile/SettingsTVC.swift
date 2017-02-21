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

    var userExists: Bool = false
    var userEmail: String? = nil

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

        updateUserStatus()

        // Configure Account cell text
        configureAccountCell()
    }

    override func viewWillAppear(_ animated: Bool) {
        updateUserStatus()
        configureAccountCell()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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

        // Pass the selected object to the new view controller.
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected section \(indexPath.section)")

        // Account
        if indexPath.section == 0 {
            // TODO - Logout or show AccountVC
            print("Now we would decide what to do ...")

            //let authManager = APIManager.sharedInstance.authHandler
            if userExists {
                print("Logging out \(userEmail)?")

                // TEMP
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "email")

                APIManager.sharedInstance.logout(completion: completedLogout)
            } else {
                print("Showing AccountVC ...")
                performSegue(withIdentifier: accountSegue, sender: self)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - User Actions

    @IBAction func done(_ sender: UIBarButtonItem) {
        print("Saving Settings ...")
        dismiss(animated: true, completion: nil)
    }

    func updateUserStatus() {
        print("\(#function)")
        let authManager = APIManager.sharedInstance.authHandler
        if let email = authManager.email {
            userExists = true
            userEmail = email
        } else {
            userExists = false
        }
        print("userExists: \(userExists)")
    }

    // TODO - pass User?
    func configureAccountCell() {
        //let authManager = APIManager.sharedInstance.authHandler
        //if let email = authManager.email {
        if userExists {
            //let email = userEmail
            print("email: \(userEmail)")
            AccountCell.textLabel?.text = "Logout \(userEmail!)"
        } else {
            AccountCell.textLabel?.text = "Login"
        }
    }

}

// MARK: - Completion Handlers
extension SettingsTVC {

    func completedLogout(suceeded: Bool) {

        // TEMP
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "email")
        userExists = false

        if suceeded {
            print("OK")
            AccountCell.textLabel?.text = "Login"
        } else {
            print("Nope")
            // TEMP
            AccountCell.textLabel?.text = "Login"
        }
    }

}
