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

protocol RootSectionViewController {
    var userManager: CurrentUserManager! { get set }
    var managedObjectContext: NSManagedObjectContext? { get set }

    // FetchedResultsController
    //var filter: NSPredicate? { get }
    //var cacheName: String? { get }
    //var sectionNameKeyPath: String? { get }
    //var fetchBatchSize: Int { get }

    // TableViewCell
    //var cellIdentifier: String { get }

    // Segues
    // var SegueIdentifier: RawRepresentable

    //func setContext(_ context: NSManagedObjectContext)

}

