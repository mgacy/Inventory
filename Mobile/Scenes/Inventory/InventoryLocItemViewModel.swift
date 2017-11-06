//
//  InventoryLocItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/23/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
//import RxCocoa
//import RxSwift

struct InventoryLocItemViewModel {

    // MARK: - Properties

    let dataManager: DataManager
    var parentObject: LocationItemListParent

    // CoreData
    //private let filter: NSPredicate? = nil
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true),
                                   NSSortDescriptor(key: "item.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input

    // MARK: - Output
    let frc: NSFetchedResultsController<InventoryLocationItem>
    let windowTitle: String

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: LocationItemListParent) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // Title
        switch self.parentObject {
        case .category(let parentCategory):
            self.windowTitle = parentCategory.name ?? "Error"
        case .location(let parentLocation):
            self.windowTitle = parentLocation.name ?? "Error"
        }

        // FetchRequest
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()
        request.predicate = parentObject.fetchPredicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}
