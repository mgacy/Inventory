//
//  AppDelegate.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/19/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData
import SwiftyBeaver
import PKHUD

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dataManager: DataManager?
    let userManager: CurrentUserManager = CurrentUserManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        /// TODO: set up CoreDataStack

        let defaults = UserDefaults.standard

        setupSwiftyBeaverLogging(defaults: defaults)

        // Check if we have already preloaded data
        let isPreloaded = defaults.bool(forKey: "isPreloaded")
        if !isPreloaded {
            log.info("Preloading data ...")
            let importer = CoreDataImporter()
            guard importer.preloadData(in: persistentContainer.viewContext) == true else {
                /// TODO: tell user why we are crashing?
                fatalError("Unable to import Unit data")
            }
            defaults.set(true, forKey: "isPreloaded")
        }

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        HUD.dimsBackground = false
        HUD.allowsInteraction = false

        /// TODO: Should we use a failable initializier with CurrentUserManager?
        //  Alteratively, we could try to login and perform the following in a completion handler with success / failure.

        dataManager = DataManager(context: persistentContainer.viewContext, userManager: userManager)
        //guard let manager = dataManager else { fatalError("Unable to instantiate DataManager") }

        // Check if we already have user + credentials
        if userManager.user != nil {
            prepareTabBarController(dataManager: dataManager!)
        } else {
            guard let loginController = storyboard.instantiateViewController(
                withIdentifier: "InitialLoginViewController") as? InitialLoginViewController else {
                    fatalError("Unable to instantiate view controller")
            }
            loginController.viewModel = InitialLoginViewModel(dataManager: dataManager!)

            self.window?.rootViewController = loginController
            self.window?.makeKeyAndVisible()
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

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Mobile")
        // swiftlint:disable:next unused_closure_parameter
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                log.error("Unresolved error \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

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
            let platform = SBPlatformDestination(appID: "***REMOVED***",
                                                 appSecret: "***REMOVED***",
                                                 encryptionKey: "***REMOVED***")
            if let userName = defaults.string(forKey: "email") {
                platform.analyticsUserName = userName
            }
            /// TODO: try to get minLevel from defaults (so user can set verbose logging)
            platform.minLevel = .warning
            log.addDestination(platform)
        #endif

        log.addDestination(console)
        //log.addDestination(file)
    }

    // func prepareTabBarController(context: NSManagedObjectContext, userManager: CurrentUserManager) {}

    func prepareTabBarController(dataManager: DataManager) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateViewController(
            withIdentifier: "TabBarViewController") as? UITabBarController else {
                fatalError("Unable to instantiate tab bar controller")
        }

        // Fix dark shadow in nav bar on segue
        tabBarController.view.backgroundColor = UIColor.white
        //tabBarController.managedObjectContext = persistentContainer.viewContext
        //tabBarController.userManager = userManager

        for child in tabBarController.viewControllers ?? [] {
            guard let navController = child as? UINavigationController
                else { fatalError("wrong view controller type") }
            /*
            guard let vc = navController.topViewController as? RootSectionViewController
                else { fatalError("wrong view controller type") }
            vc.managedObjectContext = persistentContainer.viewContext
            vc.userManager = userManager
             */
            // TEMP:
            guard let topVC = navController.topViewController else { fatalError("wrong view controller type") }
            switch topVC {
            case is InventoryDateViewController:
                guard let vc = topVC as? InventoryDateViewController else { fatalError("wrong view controller type") }
                vc.viewModel = InventoryDateViewModel(dataManager: dataManager,
                                                      rowTaps: vc.selectedObjects.asObservable())

            case is OrderDateViewController:
                guard let vc = topVC as? OrderDateViewController else { fatalError("wrong view controller type") }
                vc.viewModel = OrderDateViewModel(dataManager: dataManager, rowTaps: vc.selectedObjects.asObservable())

            case is InvoiceDateViewController:
                guard let vc = topVC as? InvoiceDateViewController else { fatalError("wrong view controller type") }
                vc.viewModel = InvoiceDateViewModel(dataManager: dataManager,
                                                    rowTaps: vc.selectedObjects.asObservable())

            case is InitialLoginViewController:
                guard let vc = topVC as? InitialLoginViewController else { fatalError("wrong view controller type") }
                vc.viewModel = InitialLoginViewModel(dataManager: dataManager)

            case is SettingsViewController:
                guard let vc = topVC as? SettingsViewController else { fatalError("wrong view controller type") }
                vc.viewModel = SettingsViewModel(dataManager: dataManager, rowTaps: vc.rowTaps.asObservable())

            default:
                fatalError("wrong view controller type")
            }
        }
        self.window?.rootViewController = tabBarController
        self.window?.makeKeyAndVisible()

        // Sync
        /*
        guard
            let inventoryNavController = tabBarController.viewControllers?[0] as? UINavigationController,
            let controller = inventoryNavController.topViewController as? InventoryDateTVC else {
                fatalError("wrong view controller type")
        }
        HUD.show(.progress)
        _ = SyncManager(context: persistentContainer.viewContext, storeID: userManager.storeID!,
                        completionHandler: controller.completedSync)
         */
    }

}
