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

class OrderViewModel {

    // MARK: - Properties

    let dataManager: DataManager
    private var order: Order

    // CoreData
    private let filter: NSPredicate
    private let sortDescriptors = [NSSortDescriptor(key: "item.name", ascending: true)]
    private let cacheName: String? = nil
    private let sectionNameKeyPath: String? = nil
    private let fetchBatchSize = 20 // 0 = No Limit

    // MARK: - Input
    let placedOrder: AnyObserver<Void>

    // MARK: - Output
    let frc: NSFetchedResultsController<OrderItem>
    let isUploading: Driver<Bool>
    let uploadResults: Observable<Event<Order>>

    var vendorName: String { return order.vendor?.name ?? "" }
    var repName: String { return "\(order.vendor?.rep?.firstName ?? "") \(order.vendor?.rep?.lastName ?? "")" }
    var email: String { return order.vendor?.rep?.email ?? "" }
    var phone: String { return order.vendor?.rep?.phone ?? "" }
    var formattedPhone: String { return format(phoneNumber: phone) ?? "" }

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

    // MARK: - Lifecycle

    required init(dataManager: DataManager, parentObject: Order) {
        self.dataManager = dataManager
        self.order = parentObject

        let _placedOrder = PublishSubject<Void>()
        self.placedOrder = _placedOrder.asObserver()

        // Upload
        let isUploading = ActivityIndicator()
        self.isUploading = isUploading.asDriver()

        self.uploadResults = _placedOrder.asObservable()
            .flatMap { _ -> Observable<Event<Order>> in
                log.info("POSTing Order ...")
                parentObject.status = OrderStatus.placed.rawValue
                return dataManager.updateOrder(parentObject)
                    .trackActivity(isUploading)
            }
            /// TODO: save context?
            .share()

        // FetchRequest
        self.filter = NSPredicate(format: "order == %@", parentObject)

        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = filter
        request.fetchBatchSize = fetchBatchSize
        request.returnsObjectsAsFaults = false

        let managedObjectContext = dataManager.managedObjectContext
        self.frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext,
                                              sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
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
        //dataManager.managedObjectContext.performSaveOrRollback()
    }

}

// MARK: - Various Classes, Extensions

// FIXME: move this somewhere more general
// Mobile Dan
// https://stackoverflow.com/a/41668104
func format(phoneNumber sourcePhoneNumber: String) -> String? {

    // Remove any character that is not a number
    let numbersOnly = sourcePhoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let length = numbersOnly.characters.count
    let hasLeadingOne = numbersOnly.hasPrefix("1")

    // Check for supported phone number length
    guard length == 7 || length == 10 || (length == 11 && hasLeadingOne) else {
        return nil
    }

    let hasAreaCode = (length >= 10)
    var sourceIndex = 0

    // Leading 1
    var leadingOne = ""
    if hasLeadingOne {
        leadingOne = "1 "
        sourceIndex += 1
    }

    // Area code
    var areaCode = ""
    if hasAreaCode {
        let areaCodeLength = 3
        guard let areaCodeSubstring = numbersOnly.characters.substring(
            start: sourceIndex, offsetBy: areaCodeLength) else {
                return nil
        }
        areaCode = String(format: "(%@) ", areaCodeSubstring)
        sourceIndex += areaCodeLength
    }

    // Prefix, 3 characters
    let prefixLength = 3
    guard let prefix = numbersOnly.characters.substring(start: sourceIndex, offsetBy: prefixLength) else {
        return nil
    }
    sourceIndex += prefixLength

    // Suffix, 4 characters
    let suffixLength = 4
    guard let suffix = numbersOnly.characters.substring(start: sourceIndex, offsetBy: suffixLength) else {
        return nil
    }

    return leadingOne + areaCode + prefix + "-" + suffix
}
