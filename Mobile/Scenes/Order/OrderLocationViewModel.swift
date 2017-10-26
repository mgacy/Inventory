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

    // MARK: - Input

    // MARK: - Output
    let errorMessages: Driver<String>
    let locations: Observable<[RemoteLocation]>

    // MARK: - Lifecycle

    init(dataManager: DataManager, collection: OrderCollection, rowTaps: Observable<IndexPath>) {
        self.dataManager = dataManager
        self.collection = collection

        // Fetch Locations
        let locationResults = dataManager.getLocations()

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
            .map { locations in
                //let factory = OrderLocationFactory(collection: collection, in: dataManager.managedObjectContext)
                //factory.generateLocations(for: locations)
                return locations
            }

        // ...
    }

}
