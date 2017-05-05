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
    let userManager: CurrentUserManager = CurrentUserManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        setupSwiftyBeaverLogging()

        /// TODO: set up CoreDataStack

        // Check if we have already preloaded data
        let defaults = UserDefaults.standard
        let isPreloaded = defaults.bool(forKey: "isPreloaded")
        if !isPreloaded {
            log.info("Preloading data ...")
            let importer = CoreDataImporter()
            importer.preloadData(in: persistentContainer.viewContext)
            defaults.set(true, forKey: "isPreloaded")
        }

        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        HUD.dimsBackground = false
        HUD.allowsInteraction = false

        /*
        //enum RootControllers: String {
        //    case inventoryRoot: "InventoryDateTVC"
        //    case orderRoot: "OrderDateTVC"
        //    case invoiceRoot: "InvoiceDateTVC"
        //    case settingsRoot: "SettingsTVC"
        //}

        let rootInventoryController = storyboard.instantiateViewController(withIdentifier: "InventoryDateTVC")
         let rootInventoryNavController = UINavigationController(rootViewController: rootInventoryController)

        let rootOrderController = storyboard.instantiateViewController(withIdentifier: "OrderDateTVC")
        let rootOrderNavController = UINavigationController(rootViewController: rootOrderController)

        let rootInvoiceController = storyboard.instantiateViewController(withIdentifier: "InvoiceDateTVC")
        let rootInvoiceNavController = UINavigationController(rootViewController: rootInvoiceController)

        let rootSettingsController = storyboard.instantiateViewController(withIdentifier: "SettingsTVC")
        let rootSettingsNavController = UINavigationController(rootViewController: rootSettingsController)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            rootInventoryNavController, rootOrderNavController,
            rootInvoiceNavController, rootSettingsNavController
        ]
        */

        guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            fatalError("wrong view controller type")
        }

        for child in tabBarController.viewControllers ?? [] {
            guard let navController = child as? UINavigationController
                else { fatalError("wrong view controller type") }
            guard let vc = navController.topViewController as? RootSectionViewController
                else { fatalError("wrong view controller type") }

            // Inject dependencies
            vc.managedObjectContext = persistentContainer.viewContext
            vc.userManager = userManager
        }

        /// TODO: Should we use a failable initializier with CurrentUserManager?
        //  Alteratively, we could try to login and perform the following in a completion handler with success / failure.

        // Check if we already have user + credentials
        if userManager.user != nil {
            //log.debug("AppDelegate: has User")
            guard
                let inventoryNavController = tabBarController.viewControllers?[0] as? UINavigationController,
                let controller = inventoryNavController.topViewController as? InventoryDateTVC else {
                    fatalError("wrong view controller type")
            }

            // Sync
            HUD.show(.progress)
            _ = SyncManager(context: persistentContainer.viewContext, storeID: userManager.storeID!, completionHandler: controller.completedSync)

            self.window?.rootViewController = tabBarController
        } else {
            //log.debug("AppDelegate: missing User")
            guard let loginController = storyboard.instantiateViewController(withIdentifier: "InitialLoginViewController") as? InitialLoginVC else {
                fatalError("Unable to instantiate view controller")
            }

            // Inject dependencies
            loginController.managedObjectContext = persistentContainer.viewContext
            loginController.userManager = userManager
            // Should we really be changing the root view controller like this?
            self.window?.rootViewController = loginController
        }

        //self.window?.makeKeyAndVisible()
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

    func setupSwiftyBeaverLogging() {
        let console = ConsoleDestination()
        //let file = FileDestination()
        let platform = SBPlatformDestination(appID: "***REMOVED***",
                                             appSecret: "***REMOVED***",
                                             encryptionKey: "***REMOVED***")

        // Config
        platform.minLevel = .warning
        //platform.analyticsUserName = ""

        // use custom format and set console output to short time, log level & message
        //console.format = "$DHH:mm:ss$d $L $M"
        // or use this for JSON output: console.format = "$J"

        // Filters

        log.addDestination(console)
        //log.addDestination(file)
        log.addDestination(platform)
    }

}
