//
//  DataManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
//import RxCocoa
import RxSwift

// swiftlint:disable file_length
// swiftlint:disable unused_closure_parameter

public enum DataManagerError: Error {
    //case dateParsing
    case missingMOC
    case missingStoreID
    case serializationError
    case otherError(error: String)
}

class DataManager {

    // MARK: - Properties

    /// TODO: specify client as conforming to NetworkServiceType protocol
    private let client: APIManager
    let managedObjectContext: NSManagedObjectContext
    //let viewContext: NSManagedObjectContext
    //let syncContext: NSManagedObjectContext
    /// TODO: use `UserManagerType`; should userManager be private?
    let userManager: CurrentUserManager

    // MARK: - Lifecycle

    init(context: NSManagedObjectContext, userManager: CurrentUserManager) {
        self.managedObjectContext = context
        self.userManager = userManager
        self.client = APIManager.sharedInstance
    }

    // MARK: General

    @discardableResult
    func saveOrRollback() -> Observable<Bool> {
        /// TODO: use `saveOrRollback()` or `performSaveOrRollback()`
        /// TODO: should we simply perform the do / catch here and materialize the error?
        return Observable.just(managedObjectContext.saveOrRollback())
    }

    /// TODO: rename
    func refreshStuff() -> Observable<Bool> {
        return refreshVendors()
            // Items
            .flatMap { result -> Observable<Bool> in
                //log.debug("\(#function) - \(result)")
                return self.refreshItems()
            }
            .flatMap { result -> Observable<Bool> in
                //log.debug("\(#function) - \(result)")
                return Observable.just(self.managedObjectContext.saveOrRollback())
        }
        //.materialize()
    }

    // Item

    //func createItem() -> Observable<> {}

    //func deleteItem(_ item: Item) -> Observable<> {}

    //func updateItem(_ item: Item) -> Observable<Bool> { return Observable.just(true) }

    func refreshItems() -> Observable<Bool> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.just(false)
            //return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.getItems(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    guard let context = self?.managedObjectContext else {
                        return false
                        //throw DataManagerError.missingMOC
                    }
                    Item.sync(with: records, in: context)
                    /*
                    do {
                        try self?.managedObjectContext.syncEntitiesNew(Item.self, with: records)
                    } catch let error {
                        log.error("\(#function) FAILED : \(error)")
                        return false
                    }
                     */
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    return false
                    //throw error
                }
        }
        //.materialize()
    }

    // ItemCategory
    /*
    func refreshItemCategories() -> Observable<Bool> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.just(false)
        }

        return client.getItemCategories(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    do {
                        try self?.managedObjectContext.syncEntities(ItemCategory.self, with: records)
                    } catch let error {
                        log.error("\(#function) FAILED : \(error)")
                        return false
                    }
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    return false
                }
        }
    }
     */
    // Vendor

    //func createVendor() -> Observable<Vendor> {}

    func refreshVendors() -> Observable<Bool> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.just(false)
            //return Observable.error(DataManagerError.missingStoreID).materialize()
        }
        return client.getVendors(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    guard let context = self?.managedObjectContext else {
                        return false
                        //throw DataManagerError.missingMOC
                    }
                    Vendor.sync(with: records, in: context)
                    /*
                    do {
                        try self?.managedObjectContext.syncEntities(Vendor.self, with: records)
                    } catch let error {
                        log.error("\(#function) FAILED : \(error)")
                        return false
                    }
                     */
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    return false
                    //throw error
                }
        }
    }

}

// MARK: - Inventory
extension DataManager {

    func createInventory() -> Observable<Event<Inventory>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.postInventory(storeID: storeID)
            //.flatMap { [weak self] response -> Observable<Inventory> in
            .map { [weak self] response -> Inventory in
                switch response.result {
                case .success(let record):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }

                    let inventoryFactory = InventoriesFactory(context: context)
                    guard let newInventory = inventoryFactory.createNewInventory(from: record, in: context) else {
                        log.error("Unable to create Inventory")
                        throw DataManagerError.otherError(error: "Unable to create Inventory")
                    }
                    return newInventory
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    //func deleteInventory(_ inventory: Inventory) -> Observable<> {}

    /// TODO: rename `completeInventory(:)`?
    func updateInventory(_ inventory: Inventory) -> Observable<Event<Inventory>> {
        guard let inventoryDict = inventory.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Inventory \(inventory)")
            return Observable.error(DataManagerError.serializationError).materialize()
        }

        return client.putInventory(inventoryDict)
            .flatMap { response -> Observable<Inventory> in
                switch response.result {
                case .success(let record):
                    inventory.remoteID = record.syncIdentifier
                    inventory.uploaded = true
                    //return inventory
                    return Observable.just(inventory)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func refreshInventory(_ inventory: Inventory) -> Observable<Event<Inventory>> {
        let remoteID = Int(inventory.remoteID)
        guard remoteID != 0 else {
            log.error("\(#function) FAILED : unable to refresh Inventory that hasn't been uploaded: \(inventory)")
            return Observable.error(DataManagerError.otherError(error: "Inventory not uploaded")).materialize()
        }

        return client.getInventory(remoteID: remoteID)
            .map { [weak self] response in
                switch response.result {
                case .success(let record):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    let factory = InventoriesFactory(context: context)
                    guard let updatedInventory = factory.updateInventory(inventory, with: record, in: context) else {
                        throw DataManagerError.otherError(error: "Error syncing")
                    }
                    return updatedInventory
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    //func refreshInventories() -> Observable<Event<[Inventory]>> {
    func refreshInventories() -> Observable<Event<Bool>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.getInventories(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    Inventory.sync(with: records, in: context)
                    /*
                    do {
                        try self?.managedObjectContext.syncEntitiesNew(Item.self, with: records)
                    } catch let error {
                        log.error("\(#function) FAILED : \(error)")
                        return false
                    }
                     */
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }
}

// MARK: - Order

extension DataManager {

    func createOrderCollection(generationMethod method: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?) -> Observable<Event<OrderCollection>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.postOrderCollection(storeID: storeID, generationMethod: method, returnUsage: returnUsage,
                                          periodLength: periodLength)
            .flatMap { [weak self] response -> Observable<OrderCollection> in
                switch response.result {
                case .success(let record):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    /*
                    guard let date = record.date.toBasicDate() else {
                        log.error("\(#function) FAILED : unable to parse date")
                        throw DataManagerError.otherError(error: "Unable to parse date")
                    }

                    let newCollection: OrderCollection = context.insertObject()
                    /// TODO: should these be part of an `.init(with:in:)` method?
                    newCollection.dateTimeInterval = date.timeIntervalSinceReferenceDate
                    newCollection.update(with: record, in: context)
                     */
                    let newCollection = OrderCollection(with: record, in: context)
                    newCollection.uploaded = false
                    newCollection.orders?.forEach { order in
                        if let `order` = order as? Order {
                            order.status = OrderStatus.pending.rawValue
                            order.updateStatus()
                        }
                    }
                    return Observable.just(newCollection)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func refreshOrderCollection(_ collection: OrderCollection) -> Observable<Event<OrderCollection>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }
        guard let dateString = collection.date.stringFromDate() else {
            log.error("\(#function) FAILED : unable to get dateString")
            return Observable.error(DataManagerError.otherError(error: "Unable to parse date")).materialize()
        }
        return client.getOrderCollection(storeID: storeID, orderDate: dateString)
            .map { [weak self] response in
                switch response.result {
                case .success(let record):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    collection.update(with: record, in: context)
                    /// TODO: handle this elsewhere?
                    collection.uploaded = true
                    return collection
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func refreshOrderCollections() -> Observable<Event<Bool>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.getOrderCollections(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    OrderCollection.sync(with: records, in: context)
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func updateOrder(_ order: Order) -> Observable<Event<Order>> {
        //return Observable.just(order).materialize()
        /// TODO: use RemoteRecords instead?
        guard let orderDict = order.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Order \(order)")
            return Observable.error(DataManagerError.serializationError).materialize()
        }

        return client.putOrder(orderDict)
            .map { [weak self] response -> Order in
                switch response.result {
                case .success(let record):
                    order.remoteID = record.syncIdentifier
                    order.status = OrderStatus.uploaded.rawValue
                    order.collection?.updateStatus()

                    /// TODO: is there a better way to handle this?
                    self?.saveOrRollback()

                    return order
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

}

// MARK: - Invoice

extension DataManager {

    func refreshInvoiceCollection(_ collection: InvoiceCollection) -> Observable<Event<InvoiceCollection>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        //let date = collection.date
        //let dateString = collection.date.shortDate
        guard let dateString = collection.date.stringFromDate() else {
            log.error("\(#function) FAILED : unable to get dateString")
            return Observable.error(DataManagerError.otherError(error: "Unable to parse date")).materialize()
        }
        return client.getInvoiceCollection(storeID: storeID, invoiceDate: dateString)
            .map { [weak self] response in
                switch response.result {
                case .success(let record):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    collection.update(with: record, in: context)
                    return collection
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func refreshInvoiceCollections() -> Observable<Event<Bool>> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.error(DataManagerError.missingStoreID).materialize()
        }

        return client.getInvoiceCollections(storeID: storeID)
            .map { [weak self] response in
                switch response.result {
                case .success(let records):
                    guard let context = self?.managedObjectContext else {
                        throw DataManagerError.missingMOC
                    }
                    InvoiceCollection.sync(with: records, in: context)
                    return true
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

    func updateInvoice(_ invoice: Invoice) -> Observable<Event<Invoice>> {
        let remoteID = Int(invoice.remoteID)
        guard let dict = invoice.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Invoice \(invoice)")
            return Observable.error(DataManagerError.serializationError).materialize()
        }
        /// TODO: mark invoice as having in-progress update
        return client.putInvoice(remoteID: remoteID, invoice: dict)
            .map { response in
                switch response.result {
                case .success:
                    invoice.uploaded = true
                    /// TODO: mark invoice as no longer having in-progress update
                    /// TODO: set .uploaded of invoice.collection if all are uploaded
                    return invoice
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    throw error
                }
            }
            .materialize()
    }

}

// MARK: - Attempt at Generic Method
/*
extension DataManager {

    func test(records: [RemoteMenuItem]) -> Observable<Void> {
        try? managedObjectContext.syncEntitiesNew(MenuItem.self, with: records)
        return Observable.just(())
    }

    func refreshItemsAlt() -> Observable<Bool> {
        guard let storeID = userManager.storeID else {
            log.error("\(#function) FAILED : no storeID")
            return Observable.just(false)
        }
        return client.getItems(storeID: storeID)
            .flatMap { response -> Bool in
                return self.syncEntitiesB(Item.self, with: response)
                //return true
        }
    }

    private func syncEntitiesA<M: NewSyncable, R>(_ entity: M, with response: DataResponse<[R]>) -> Bool where R == M.RemoteType {
        //return true
        switch response.result {
        case .success(let records):
            do {
                try managedObjectContext.syncEntitiesNew(M, with: records)
            } catch let error {
                log.error("\(#function) FAILED : \(error)")
                return false
            }
            return true
        case .failure(let error):
            log.warning("\(#function) FAILED : \(error)")
            return false
        }
    }

    private func syncEntitiesB<M: NewSyncable, R>(_ entity: M, with response: DataResponse<[R]>) -> Bool where M: NSManagedObject, R == M.RemoteType {
        switch response.result {
        case .success(let records):
            M.sync(with: records, in: managedObjectContext)
            /*
             do {
             try managedObjectContext.syncEntitiesNew(M, with: records)
             } catch let error {
             log.error("\(#function) FAILED : \(error)")
             return false
             }
             */
            return true
        case .failure(let error):
            log.warning("\(#function) FAILED : \(error)")
            return false
        }
    }

}
*/
// MARK: - Authentication

/// TODO: make this conform to a protocol?
extension DataManager {

    /// TODO: mark as @discardable and return Observable<Event<User>>?
    public func login(email: String, password: String) -> Observable<Event<Bool>> {
        return Observable.create { observer in
            self.userManager.login(email: email, password: password) { error in
                if let error = error {
                    log.warning("\(#function) ERROR : \(error)")
                    observer.onError(error)
                    //observer.onNext(true)
                    //observer.onCompleted()
                } else {
                    log.debug("We logged in")
                    observer.onNext(true)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
        .materialize()
    }

    public func logout() -> Observable<Bool> {
        /// TODO: check for pending Inventory / Invoice / Order; throw error and use `.materialize()`
        /// TODO: return if already logged out
        //return Observable.create { observer in
        self.userManager.logout { success in
            log.debug("logout result: \(success)")
            switch success {
            case true:
                log.verbose("Logout: Success")
            case false:
                log.verbose("Logout: Failure")
            }
            //let deletionResult = self.deleteData(in: self.managedObjectContext)
        }
        // NOTE: this currently starts deleting data before we have received a response from server
        log.verbose("Deleting data ...")
        return deleteData(in: self.managedObjectContext)

        //return Disposables.create()
        //}
    }

    public func signUp(username: String, email: String, password: String) -> Observable<Event<Bool>> {
        return Observable.create { observer in
            self.userManager.signUp(username: username, email: email, password: password) { error in
                if let error = error {
                    log.warning("\(#function) ERROR : \(error)")
                    observer.onError(error)
                } else {
                    log.debug("We signed up")
                    observer.onNext(true)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
            }
            .materialize()
    }

    private func deleteData(in context: NSManagedObjectContext) -> Observable<Bool> {
        /// TODO: use cascade rules to reduce list of entities we need to manually delete

        // Inventory
        do {
            try managedObjectContext.deleteEntities(Inventory.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete Inventories")
        }
        // Order
        do {
            try managedObjectContext.deleteEntities(OrderCollection.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete OrderCollections")
        }
        // Invoice
        do {
            try managedObjectContext.deleteEntities(InvoiceCollection.self)
        } catch {
            log.error("\(#function) FAILED: unable to delete InvoiceCollections")
        }
        // Item
        do {
            try managedObjectContext.deleteEntities(Item.self)
        } catch {
            log.error("\(#function) FAILED : unable to delete Items")
        }
        // ItemCategory
        do {
            try managedObjectContext.deleteEntities(ItemCategory.self)
        } catch {
            log.error("\(#function) FAILED : unable to delete ItemCategories")
        }
        // Vendor
        do {
            try managedObjectContext.deleteEntities(Vendor.self)
        } catch {
            log.error("\(#function) FAILED : unable to delete Vendors")
        }

        let result = managedObjectContext.saveOrRollback()
        log.info("Save result: \(result)")
        return Observable.just(result)
    }
}
