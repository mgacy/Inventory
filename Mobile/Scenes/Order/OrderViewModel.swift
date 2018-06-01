//
//  OrderViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/18/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift

final class OrderViewModel {

    // MARK: Dependencies
    //private let dependencies: Dependency
    private let dataManager: DataManager
    private let order: Order

    // MARK: Properties
    let frc: NSFetchedResultsController<OrderItem>
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Order>>

    var rawOrderStatus: Int16 { return order.status }
    var vendorName: String { return order.vendor?.name ?? "" }
    var repName: String { return "\(order.vendor?.rep?.firstName ?? "") \(order.vendor?.rep?.lastName ?? "")" }
    var email: String { return order.vendor?.rep?.email ?? "" }
    var phone: String { return order.vendor?.rep?.phone ?? "" }
    var formattedPhone: String { return phone.formattedPhoneNumber() ?? "" }

    var canMessageOrder: Bool {
        guard order.vendor?.rep?.phone != nil else {
            return false
        }
        /// TODO: what about handling upload of .placed Order if upload previously failed?
        guard order.status == OrderStatus.pending.rawValue else {
            return false
        }
        return true
    }

    /// TODO: make optional?
    var orderSubject: String { return "Order for \(order.collection?.date.stringFromDate() ?? "")" }

    var orderMessage: String? {
        guard let items = order.items else { return nil }

        var messageItems: [String] = []
        for case let item as OrderItem in items {
            guard let quantity = item.quantity else { continue }

            if quantity.doubleValue > 0.0 {
                guard let name = item.item?.name else { continue }
                messageItems.append("\n\(name) \(quantity) \(item.orderUnit?.abbreviation ?? "")")
            }
        }

        if messageItems.count == 0 { return nil }

        messageItems.sort()
        // swiftlint:disable:next line_length
        let message = "Order for \(order.collection?.date.stringFromDate() ?? ""):\n\(messageItems.joined(separator: ""))"
        log.debug("Order Message: \(message)")
        return message
    }

    // CoreData
    private let filter: NSPredicate
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    //private let cacheName: String? = nil
    //private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Lifecycle

    init(dependency: Dependency, bindings: Bindings) {
        self.dataManager = dependency.dataManager
        self.order = dependency.parentObject

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = bindings.placedOrder
            .flatMap { _ -> Observable<Event<Order>> in
                log.info("POSTing Order ...")
                dependency.parentObject.status = OrderStatus.placed.rawValue
                return dependency.dataManager.updateOrder(dependency.parentObject)
                    .trackActivity(isUploading)
            }
            /// TODO: save context?
            .share()

        // FetchRequest
        self.filter = NSPredicate(format: "order == %@", dependency.parentObject)

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false
        self.frc = dependency.dataManager.createFetchedResultsController(fetchRequest: request)

        // Selection
        // ...
    }

    // MARK: - Actions

    //func emailOrder() {}

    // MARK: - Model

    func updateOrderStatus() {
        order.updateStatus()
    }

    func cancelOrder() {
        order.status = OrderStatus.empty.rawValue
    }

    func setOrderToZero(forItemAtIndexPath indexPath: IndexPath) {
        let orderItem = frc.object(at: indexPath)
        orderItem.quantity = 0
        _ = dataManager.saveOrRollback()
    }

    // MARK: -

    struct Dependency {
        let dataManager: DataManager
        let parentObject: Order
    }

    struct Bindings {
        let rowTaps: Observable<IndexPath>
        let placedOrder: Observable<Void>
    }

}

// extension OrderViewModel: AttachableViewModelType {}
