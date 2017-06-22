//
//  OrderViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/18/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
//import CoreData
import SwiftyJSON

//
//  Dynamic.swift
//  MVVMExample
//
//  Created by Dino Bartosak on 25/09/16.
//  Copyright © 2016 Toptal. All rights reserved.
//

class Dynamic<T> {
    typealias Listener = (T) -> ()
    var listener: Listener?

    func bind(_ listener: Listener?) {
        self.listener = listener
    }

    func bindAndFire(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }

    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ val: T) {
        value = val
    }
}

class OrderViewModel {

    typealias CompletionHandlerType = (JSON?, Error?) -> Void

    private var order: Order

    var vendorName: String
    var repName: String
    var phone: String
    var email: String

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

    var orderMessage: String? {
        guard let items = order.items else { return nil }

        var messageItems: [String] = []
        for case let item as OrderItem in items {
            guard let quantity = item.quantity else { continue }

            if Int(quantity) > 0 {
                guard let name = item.item?.name else { continue }
                messageItems.append("\n\(name) \(quantity) \(item.orderUnit?.abbreviation ?? "")")
            }
        }

        if messageItems.count == 0 { return nil }

        messageItems.sort()
        let message = "Order for \(order.collection?.date ?? ""):\n\(messageItems.joined(separator: ""))"
        log.debug("Order Message: \(message)")
        return message
    }

    // MARK: - Lifecycle

    required init(forOrder order: Order) {
        self.order = order
        self.vendorName = order.vendor?.name ?? ""
        self.repName = order.vendor?.rep?.firstName ?? ""
        self.phone = order.vendor?.rep?.phone ?? ""
        self.email = ""
    }

    // MARK: - Actions

    //func emailOrder() {}

    func cancelOrder() {
        order.status = OrderStatus.empty.rawValue
    }

    // MARK: - Completion Handlers

    func postOrder(completion: @escaping (Bool, JSON) -> Void) {
        order.status = OrderStatus.placed.rawValue

        // Serialize and POST Order
        guard let json = order.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Order")
            return completion(false, JSON([]))
        }
        log.info("POSTing Order ...")
        log.verbose("Order: \(json)")
        APIManager.sharedInstance.postOrder(order: json, completion: completion)
    }

    /// TODO: change completion handler to accept standard (JSON?, Error?)

    func completedPostOrder() {
        order.status = OrderStatus.uploaded.rawValue

        // Set .uploaded of parentObject.collection if all are uploaded
        //order.collection?.updateStatus()
    }

}

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

// Mobile Dan
// https://stackoverflow.com/a/41668104
extension String.CharacterView {
    /// This method makes it easier extract a substring by character index where a character is viewed as a human-readable character (grapheme cluster).
    internal func substring(start: Int, offsetBy: Int) -> String? {
        guard let substringStartIndex = self.index(startIndex, offsetBy: start, limitedBy: endIndex) else {
            return nil
        }

        guard let substringEndIndex = self.index(startIndex, offsetBy: start + offsetBy, limitedBy: endIndex) else {
            return nil
        }

        return String(self[substringStartIndex ..< substringEndIndex])
    }
}
