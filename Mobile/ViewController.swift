//
//  ViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/19/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

protocol RootSectionViewController: class {
    var managedObjectContext: NSManagedObjectContext! { get set }
    var userManager: CurrentUserManager! { get set }

    // FetchedResultsController
    //var filter: NSPredicate? { get }
    //var cacheName: String? { get }
    //var sectionNameKeyPath: String? { get }
    //var fetchBatchSize: Int { get }

    // TableViewCell
    //var cellIdentifier: String { get }

    // Segues
    //var SegueIdentifier: RawRepresentable

    //func setupTableView()

    // User Actions
    //func refreshTable(_ refreshControl: UIRefreshControl)
    //func newTapped(_ sender: AnyObject)

    // CompletionHandlers
    //func completedGetResourceCollection(json: JSON?, error: Error?) -> Void
    //func completedGetExistingResource(json: JSON?, error: Error?) -> Void
    //func completedGetNewResource(json: JSON?, error: Error?) -> Void
    //func completedSync(json: JSON?, error: Error?) -> Void

    //func deleteChildren

}
/*
// https://blog.krw.io/2016/02/04/dependency-injection-uitabbarcontroller/
class RootViewController: UITabBarController, UITabBarControllerDelegate {

    // MARK: - Properties

    var userManager: CurrentUserManager!
    var managedObjectContext: NSManagedObjectContext!

    // MARK: - Lifecycle

    //required init?(coder: NSCoder) {
    //    fatalError("init(coder:) is not supported")
    //}

    override func viewDidLoad() {
        for child in self.childViewControllers {
            guard
                let nc = child as? UINavigationController,
                let vc = nc.topViewController as? RootSectionViewController else {
                    fatalError("wrong view controller type")
            }
            vc.managedObjectContext = managedObjectContext
            vc.userManager = userManager
        }
        super.viewDidLoad()
        // NOTE - we must set the delegate to use the method below
        //self.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    /*
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Get your view controller using the correct protocol.
        // Use guard to make sure the correct type of viewController has been provided.
        guard
            let nc = viewController as? UINavigationController,
            let vc = nc.topViewController as? RootSectionViewController else {
                fatalError("wrong view controller type")
        }

        // Assign the protocol variable to whatever you want injected into the class instance.
        vc.managedObjectContext = managedObjectContext
        vc.userManager = userManager
        // This method is declared in the protocol to by type bool, so you need to return a bool.
        return true
    }
    */
}
*/
