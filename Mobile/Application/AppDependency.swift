//
//  AppDependency.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/1/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

// Inspired by:
// http://merowing.info/2017/04/using-protocol-compositon-for-dependency-injection/
// https://www.swiftbysundell.com/posts/dependency-injection-using-factories-in-swift

import CoreData

protocol HasDataManager {
    var dataManager: DataManager { get }
}

protocol HasUserManager {
    var userManager: CurrentUserManager { get }
}

struct AppDependency: HasDataManager, HasUserManager {
    let dataManager: DataManager
    let userManager: CurrentUserManager

    init(container: NSPersistentContainer) {

        /// TODO: initialize a SessionManager here and pass to different components
        self.userManager = CurrentUserManager()
        self.dataManager = DataManager(container: container, userManager: userManager)
    }
}
