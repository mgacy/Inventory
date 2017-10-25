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

    // MARK: - Input

    // MARK: - Output

    // MARK: - Lifecycle

    // swiftlint:disable:next function_body_length
    init(dataManager: DataManager, rowTaps: Observable<Inventory>) {
        self.dataManager = dataManager

        // ...
    }

}
