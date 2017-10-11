//
//  OrderVendorViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct OrderVendorViewModel {

    // MARK: - Properties

    private let dataManager: DataManager
    private let parentObject: OrderCollection

    // CoreData
    private let filter: NSPredicate?
    private let sortDescriptors = [NSSortDescriptor(key: "vendor.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    //letCompleteTaps

    // MARK: - Output
    let frc: NSFetchedResultsController<Order>
    //let isRefreshing: Driver<Bool>
    //let hasRefreshed: Driver<Bool>
    //let showSelection: Observable<Order>
    //let errorMessages: Driver<String>

    init(dataManager: DataManager, parentObject: OrderCollection, rowTaps: Observable<Order>) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Activity

        // Selection

        // Navigation
        //showSelection =

        // Errors
        //errorMessages =

        // FetchRequest
        filter = NSPredicate(format: "collection == %@", parentObject)
        let request: NSFetchRequest<Order> = Order.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}
