//
//  AppCoordinator.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import UIKit
import RxSwift

class AppCoordinator: BaseCoordinator<Void> {

    private let window: UIWindow
    //private var persistentContainer: NSPersistentContainer!
    private let userManager: CurrentUserManager
    private let dataManager: DataManager

    init(window: UIWindow, userManager: CurrentUserManager, dataManager: DataManager) {
        self.window = window
        self.userManager = userManager
        self.dataManager = dataManager
    }

    // NOTE: this will return whatever `to.start()` returns
    override func start() -> Observable<Void> {
        //log.debug("\(#function)")

        // Check if we already have user + credentials
        if userManager.user != nil {
            log.debug("Have User")
            let tabBarCoordinator = TabBarCoordinator(window: window, dataManager: dataManager)
            return coordinate(to: tabBarCoordinator)

        } else {
            log.debug("Missing User")
            return showLogin()
                .flatMap { [weak self] result -> Observable<Void> in
                    //log.debug("\(#function) - result: \(result)")
                    guard let strongSelf = self else { return .empty() }
                    return strongSelf.showTabBar()
                }
        }

        /*
        let defaults = UserDefaults.standard
        createPersistentContainer { container in
            self.persistentContainer = container

            // Check if we have already preloaded data
            let isPreloaded = defaults.bool(forKey: "isPreloaded")
            if !isPreloaded {
                log.info("Preloading data ...")
                let importer = CoreDataImporter()
                guard importer.preloadData(in: container.viewContext) == true else {
                    /// TODO: tell user why we are crashing?
                    fatalError("Unable to import Unit data")
                }
                defaults.set(true, forKey: "isPreloaded")
            }

            /// TODO: Should we use a failable initializier with CurrentUserManager?
            //  Alteratively, we could try to login and perform the following in a completion handler with success / failure.

            /// TODO: initialize a SessionManager here and pass to different components
            let userManager = CurrentUserManager()
            let dataManager = DataManager(container: container, userManager: userManager)
            //self.dataManager = dataManager

            // Check if we already have user + credentials
            if userManager.user != nil {
                log.debug("Have User")
                //let tabBarCoordinator = TabBarCoordinator(window: window, dataManager: dataManager)
                //return coordinate(to: tabBarCoordinator)

            } else {
                log.debug("Missing User")
                //let loginCoordinator = LoginCoordinator(window: window, dataManager: dataManager)
                //return coordinate(to: loginCoordinator)
            }

        }
        */
    }

    private func showTabBar() -> Observable<Void> {
        let tabBarCoordinator = TabBarCoordinator(window: self.window, dataManager: self.dataManager)
        return coordinate(to: tabBarCoordinator)
    }

    private func showLogin() -> Observable<Void> {
        let loginCoordinator = InitialLoginCoordinator(window: window, dataManager: dataManager)
        return coordinate(to: loginCoordinator)
    }

    /*
    // MARK: - Core Data stack
    /// TODO: move into separate object

    private let configuredContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Mobile")
        let defaultURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Mobile.sqlite")
        let storeDescription = NSPersistentStoreDescription(url: defaultURL)
        storeDescription.shouldMigrateStoreAutomatically = false
        container.persistentStoreDescriptions = [storeDescription]
        return container
    }()

    private func createPersistentContainer(migrating: Bool = false, progress: Progress? = nil, completion: @escaping (NSPersistentContainer) -> Void) {
        configuredContainer.loadPersistentStores { _, error in
            if error == nil {
                /// TODO: set mergePolicy
                completion(self.configuredContainer)
                //DispatchQueue.main.async { completion(self.configuredContainer) }
            } else {
                log.debug("There was an error loading the persistent stores: \(error!)")
                guard !migrating else {
                    log.error("\(#function) FAILED : unable to migrate store: \(error!)")
                    fatalError("was unable to migrate store")
                }
                self.destroyStore(for: self.configuredContainer)
                self.createPersistentContainer(migrating: true, progress: progress, completion: completion)
                /*
                DispatchQueue.global(qos: .userInitiated).async {
                    self.destroyStore(for: self.configuredContainer)
                    self.createPersistentContainer(migrating: true, progress: progress, completion: completion)
                }
                */
            }
        }
    }

    private func destroyStore(for container: NSPersistentContainer) {
        /// TODO: should we simply move the store?
        // see: https://code.tutsplus.com/tutorials/core-data-and-swift-migrations--cms-25084
        let psc = container.persistentStoreCoordinator
        let dbURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Mobile.sqlite")
        do {
            try psc.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)

            // We will need to reload Units after we destroy the store
            UserDefaults.standard.set(false, forKey: "isPreloaded")
        } catch let error {
            log.error("\(#function) FAILED : unable to destroy persistent store: \(error)")
        }
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                log.error("Unresolved error \(nserror), \(nserror.userInfo)")
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    */
}
