//
//  OrderViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/18/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import SwiftyJSON

class OrderViewModel {

    typealias CompletionHandlerType = (JSON?, Error?) -> Void

    private var order: Order

    var vendorName: String { return order.vendor?.name ?? "" }
    var repName: String { return "\(order.vendor?.rep?.firstName ?? "") \(order.vendor?.rep?.lastName ?? "")" }
    var email: String { return order.vendor?.rep?.email ?? "" }
    var phone: String { return order.vendor?.rep?.phone ?? "" }

    var formattedPhone: String {
        return format(phoneNumber: phone) ?? ""
    }

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

            if Int(quantity) > 0 {
                guard let name = item.item?.name else { continue }
                messageItems.append("\n\(name) \(quantity) \(item.orderUnit?.abbreviation ?? "")")
            }
        }

        if messageItems.count == 0 { return nil }

        messageItems.sort()
        let message = "Order for \(order.collection?.date.stringFromDate() ?? ""):\n\(messageItems.joined(separator: ""))"
        log.debug("Order Message: \(message)")
        return message
    }

    // MARK: - Lifecycle

    required init(forOrder order: Order) {
        self.order = order
    }

    // MARK: - Actions

    //func emailOrder() {}

    func cancelOrder() {
        order.status = OrderStatus.empty.rawValue
    }

    // MARK: - Completion Handlers

    func postOrder(completion: @escaping (Bool, Error?) -> Void) {
        order.status = OrderStatus.placed.rawValue

        guard let json = order.serialize() else {
            log.error("\(#function) FAILED : unable to serialize Order")
            return completion(false, nil)
        }
        log.info("POSTing Order ...")
        log.verbose("Order: \(json)")
        APIManager.sharedInstance.postOrder(order: json) { (json: JSON?, error: Error?) in
            guard error == nil else {
                //log.error("\(#function) FAILED : unable to POST order \(order)")
                log.error("\(#function) FAILED : \(String(describing: error))")
                return completion(false, error)
            }
            guard let json = json else {
                log.error("\(#function) FAILED : unable to get JSON")
                return completion(false, nil)
            }
            guard let remoteID = json["id"].int32 else {
                log.error("\(#function) FAILED : unable to get remoteID")
                return completion(false, nil)
            }
            self.order.remoteID = remoteID
            self.order.status = OrderStatus.uploaded.rawValue
            //order.collection?.updateStatus()

            completion(true, nil)
        }
    }

}

// MARK: - Various Classes, Extensions

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
