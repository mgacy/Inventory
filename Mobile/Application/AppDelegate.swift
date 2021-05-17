//
//  AppDelegate.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/19/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import RxSwift
import SwiftyBeaver

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var persistentContainer: NSPersistentContainer!
    var window: UIWindow?
    private var appCoordinator: AppCoordinator!
    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let defaults = UserDefaults.standard
        setupSwiftyBeaverLogging(defaults: defaults)

        createPersistentContainer { container in
            self.persistentContainer = container

            // Check if we have already preloaded data
            let isPreloaded = defaults.bool(forKey: "isPreloaded")
            if !isPreloaded {
                log.info("Preloading data ...")
                let importer = CoreDataImporter()
                guard importer.preloadData(in: container.viewContext) == true else {
                    // TODO: tell user why we are crashing?
                    fatalError("Unable to import Unit data")
                }
                defaults.set(true, forKey: "isPreloaded")
            }

            // View Stuff
            self.window = UIWindow(frame: UIScreen.main.bounds)
            HUD.dimsBackground = false
            HUD.allowsInteraction = false

            self.appCoordinator = AppCoordinator(window: self.window!, container: container)
            self.appCoordinator.start()
                .subscribe()
                //.subscribe(onNext: { result in
                //    log.debug("\(#function) : next : \(result)")
                //})
                .disposed(by: self.disposeBag)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        // Saves changes in the application's managed object context.
        self.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - State Restoration
    /*

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }

    */
    // MARK: - Core Data stack

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
                // TODO: set mergePolicy
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
        // TODO: should we simply move the store?
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

    // MARK: - Setup

    func setupSwiftyBeaverLogging(defaults: UserDefaults) {
        let console = ConsoleDestination()
        //let file = FileDestination()

        // use custom format and set console output to short time, log level & message
        //console.format = "$DHH:mm:ss$d $L $M"
        // or use this for JSON output: console.format = "$J"

        // Filters

        #if !(arch(i386) || arch(x86_64)) && os(iOS)
        let platform = SBPlatformDestination(appID: AppSecrets.loggerAppID,
                                             appSecret: AppSecrets.loggerAppSecret,
                                             encryptionKey: AppSecrets.loggerEncryptionKey)
        if let userName = defaults.string(forKey: "email") {
            platform.analyticsUserName = userName
        }
        // TODO: try to get minLevel from defaults (so user can set verbose logging)
        platform.minLevel = .warning
        log.addDestination(platform)
        #endif

        log.addDestination(console)
        //log.addDestination(file)
    }

}
