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

    let accountSegue = "showAccount"

    @IBOutlet weak var AccountCell: UITableViewCell!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
