//
//  CoreDataStack.swift
//  Mobile
//
//  https://swifting.io/blog/2016/09/25/25-core-data-in-ios10-nspersistentcontainer/
//
//

import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()
    var errorHandler: (Error) -> Void = {_ in }

    lazy var persistentContainer: NSPersistentContainer = {
        //let container = NSPersistentContainer(name: "DataModel")
        let container = NSPersistentContainer(name: "Mobile")
        // swiftlint:disable:next unused_closure_parameter
        container.loadPersistentStores(completionHandler: { [weak self](storeDescription, error) in
            if let error = error {
                NSLog("CoreData error \(error), \(String(describing: error._userInfo))")
                self?.errorHandler(error)
            }
        })
        return container
    }()

    lazy var viewContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()

    // Optional
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()

    func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.viewContext.perform {
            block(self.viewContext)
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.persistentContainer.performBackgroundTask(block)
    }
}
