//
//  OrderContainerViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

class OrderContainerViewModel {

    // MARK: - Properties

    let dataManager: DataManager
    let parentObject: OrderCollection

    // CoreData

    // MARK: - Input

    // MARK: - Output

    // MARK: - Lifecycle

    init(dataManager: DataManager, parentObject: OrderCollection) {
        self.dataManager = dataManager
        self.parentObject = parentObject
    }
}
