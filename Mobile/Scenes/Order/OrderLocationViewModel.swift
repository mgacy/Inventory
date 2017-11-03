//
//  OrderLocationViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct OrderLocationViewModel {

    // MARK: - Properties

    /// TODO: make private
    let dataManager: DataManager
    let collection: OrderCollection
    let factory: OrderLocationFactory

    // MARK: - Input

    // MARK: - Output
    let isRefreshing: Driver<Bool>
    let showTable: Driver<Bool>
    let locations: Observable<[RemoteLocation]>
    let errorMessages: Driver<String>

    // MARK: - Lifecycle

    init(dataManager: DataManager, collection: OrderCollection) {
        self.dataManager = dataManager
        self.collection = collection
        self.factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)

        // Activity
        let isRefreshing = ActivityIndicator()
        self.isRefreshing = isRefreshing.asDriver()

        // Fetch Locations
        let locationResults = dataManager.getLocations()
            .trackActivity(isRefreshing)
            .share()

        self.showTable = locationResults
            .elements()
            .map { locations -> Bool in
                return locations.count > 0
            }
            .startWith(false)
            .asDriver(onErrorJustReturn: false)

        // Errors
        self.errorMessages = locationResults.errors()
            .map { error in
                log.debug("\(#function) ERROR : \(error)")
                switch error {
                default:
                    return "There was a problem"
                }
            }
            .asDriver(onErrorJustReturn: "Other Error")

        self.locations = locationResults.elements()
    }

}
