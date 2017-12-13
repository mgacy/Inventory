//
//  OrderLocCatViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import RxCocoa
import RxSwift

struct OrderLocCatViewModel {

    // MARK: - Properties

    private let dataManager: DataManager
    private let location: RemoteLocation
    private let factory: OrderLocationFactory

    // MARK: - Input

    // MARK: - Output
    let navTitle: String
    let categories: Observable<[RemoteItemCategory]>

    // MARK: - Lifecycle

    init(dataManager: DataManager, location: RemoteLocation, factory: OrderLocationFactory) {
        guard location.locationType == .category else {
            fatalError("\(#function) FAILED : wrong RemoteLocation type: \(location)")
        }

        self.dataManager = dataManager
        self.location = location
        self.factory = factory

        self.navTitle = location.name
        self.categories = Observable.just(location.categories)
    }

}
