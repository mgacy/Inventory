//
//  ItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct ItemViewModel {

    // MARK: Properties

    let dataManager: DataManager

    // CoreData
    private let sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    // let addTaps: AnyObserver<Void>

    // MARK: - Output
    let frc: NSFetchedResultsController<Item>

    // MARK: - Lifecycle

    init(dataManager: DataManager, rowTaps: Observable<IndexPath>) {
        self.dataManager = dataManager

        // FetchRequest
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        //request.predicate = filter
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        self.frc = dataManager.createFetchedResultsController(fetchRequest: request)
    }

}
