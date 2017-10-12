//
//  InitialLoginViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

struct InitialLoginViewModel {

    // MARK: - Properties

    //private let dataManager: DataManager
    let dataManager: DataManager

    // CoreData

    // MARK: - Input

    // MARK: - Output

    // MARK: - Lifecycle

    init(dataManager: DataManager) {
        self.dataManager = dataManager

        // ...

        //let managedObjectContext = dataManager.managedObjectContext
    }

}
