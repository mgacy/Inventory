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
// TODO: does `remoteID` mis-represent the relationship?

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
        // swiftlint:disable:next identifier_name
        if let _orderItemDict = fetchOrderItemDict(for: collection, in: context) {
            //log.debug("orderItemDict: \(_orderItemDict)\n")
            self.orderItemDict = _orderItemDict
        }
    }

    // MARK: - New
    /*
    func makeOrderLocations(forLocations locations: [RemoteLocation]) {
        for location in locations {
            let newLocation = OrderLocation(with: location, in: context)

            switch location.locationType {
            case .category:
                print("a")
                //let newLocCategory = OrderLocationCategory(
            case .item:
                print("b")
            }
        }
    }
    */
    // MARK: - Generation

    func getOrderItems(forCategoryType category: RemoteItemCategory) -> [OrderItem]? {
        guard let categoryItems = category.items else {
            return nil
        }
        return categoryItems.flatMap { self.orderItemDict[$0.syncIdentifier] }
    }

    func getOrderItems(forItemType location: RemoteLocation) -> [OrderItem]? {
        //guard location.locationType == .item else { log.warning("\(#function) : tried passing .category type") }
        return location.items.flatMap { self.orderItemDict[$0.syncIdentifier] }
    }

    // MARK: - Private

    private func fetchOrderItemDict(for collection: OrderCollection, in context: NSManagedObjectContext) -> [Int32: OrderItem]? {
        // TODO: simply fetch Orders and prefetch "item" (and "item.item")?
        guard let orders = collection.orders else { return nil }

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.predicate = NSPredicate(format: "order IN %@", orders)
        request.relationshipKeyPathsForPrefetching = ["item"]

        // TODO: complete (some of) the following
        //request.sortDescriptors = []
        //request.includesSubentities = true
        //request.propertiesToFetch = ["item"]
        //request.propertiesToGroupBy = []

        do {
            let fetchResults = try context.fetch(request)
            return fetchResults.toDictionary { $0.item?.remoteID ?? 0 }
        } catch let error {
            log.error("\(#function) FAILED : \(error)")
            return nil
        }
    }

}
