//
//  HomeViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import RxSwift

struct HomeViewModel {

    // MARK: Properties

    //private let dataManager: DataManager
    let dataManager: DataManager

    // CoreData

    // MARK: - Input
    // let settingsTaps:

    // MARK: - Output
    // storeName / navTitle

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

}
