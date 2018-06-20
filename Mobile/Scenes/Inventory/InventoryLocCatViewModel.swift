//
//  InventoryLocationCategoryViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
//import RxCocoa
//import RxSwift

struct InventoryLocCatViewModel {

    // MARK: - Properties

    private let dataManager: DataManager
    private let parentObject: InventoryLocation

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "position", ascending: true),
                                   NSSortDescriptor(key: "name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input

    // MARK: - Output
    let frc: NSFetchedResultsController<InventoryLocationCategory>
    var locationName: String { return parentObject.name ?? "Error" }

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: InventoryLocation) {
        self.dataManager = dataManager
        self.parentObject = parentObject

        // FetchRequest
        let request: NSFetchRequest<InventoryLocationCategory> = InventoryLocationCategory.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = NSPredicate(format: "location == %@", parentObject)
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dataManager.makeFetchedResultsController(fetchRequest: request)
    }

}
