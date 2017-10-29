//
//  OrderLocationFactory.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/29/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData

/*
// MARK: - OrderLocation
/// TODO: does `remoteID` mis-represent the relationship?

struct OrderLocation {
    //let remoteID: Int32
    let name: String
    //let position: Int
    let locationType: RemoteLocationType
    //let items: [OrderLocationItem]?
    let items: [OrderItem]?
    let categories: [OrderLocationCategory]?
}

struct OrderLocationCategory {
    //let remoteID: Int32
    let name: String
    //let position: Int
    //let category: ItemCategory
    let items: [OrderLocationItem]
}

struct OrderLocationItem {
    //let remoteID: Int32
    //let position: Int
    //let location: RemoteLocation
    //let category: ItemCategory?
    //let locationType:
    let orderItem: OrderItem
}
*/
// MARK: - Factory

class OrderLocationFactory {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let collection: OrderCollection
    private var orderItemDict: [Int32: OrderItem]

    // MARK: - Lifecycle
    /*
    init?(collection: OrderCollection, locations: [RemoteLocation], in context: NSManagedObjectContext) {
        self.collection = collection
        self.locations = locations
        self.context = context
        guard let _orderItemDict = fetchOrderItemDict(for: collection, in: context) else {
            return nil
        }
        self.orderItemDict = _orderItemDict
    }
    */
    init(collection: OrderCollection, in context: NSManagedObjectContext) {
        self.collection = collection
        self.context = context
        self.orderItemDict = [:]
        //self.orderItemDict = fetchOrderItemDict(for: collection, in: context) ?? [:]
        if let _orderItemDict = fetchOrderItemDict(for: collection, in: context) {
            //log.debug("orderItemDict: \(_orderItemDict)\n")
            self.orderItemDict = _orderItemDict
        }
    }

    // MARK: - Generation

    func getLocations(forCategoryType category: RemoteItemCategory) -> [OrderItem]? {
        guard let categoryItems = category.items else {
            return nil
        }
        return categoryItems.flatMap { self.orderItemDict[$0.syncIdentifier] }
    }

    func getLocations(forItemType location: RemoteLocation) -> [OrderItem]? {
        return location.items.flatMap { self.orderItemDict[$0.syncIdentifier] }
    }

    // MARK: - Private

    private func fetchOrderItemDict(for collection: OrderCollection, in context: NSManagedObjectContext) -> [Int32: OrderItem]? {
        /// TODO: simply fetch Orders and prefetch "item" (and "item.item")?
        guard let orders = collection.orders else { return nil }

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.predicate = NSPredicate(format: "order IN %@", orders)

        /// TODO: complete (some of) the following
        //request.sortDescriptors = []
        //request.includesSubentities = true
        //request.propertiesToFetch = ["item"]
        //request.propertiesToGroupBy = []
        request.relationshipKeyPathsForPrefetching = ["item"]

        do {
            let fetchResults = try context.fetch(request)
            //log.debug("fetchResults: \(fetchResults)\n")
            //return fetchResults.toDictionary { $0.itemID }
            return fetchResults.toDictionary { $0.item?.remoteID ?? 0 }
        } catch let error {
            log.error("\(#function) FAILED : \(error)")
            return nil
        }
    }

}
