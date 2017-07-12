//
//  InvoiceItemViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/12/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

struct InvoiceItemViewModel: SubItemCellViewModel {
    private var invoiceItem: InvoiceItem
    private var item: Item
    private var status: ItemStatus {
        switch invoiceItem.status {
        case InvoiceItemStatus.pending.rawValue:
            return .pending
        case InvoiceItemStatus.received.rawValue:
            return .normal
        case InvoiceItemStatus.damaged.rawValue:
            return .warning
        case InvoiceItemStatus.outOfStock.rawValue:
            return .warning
        case InvoiceItemStatus.wrongItem.rawValue:
            return .warning
        //case InvoiceItemStatus.promo.rawValue:
        //return ColorPalette.navyColor
        //case InvoiceItemStatus.substitute.rawValue:
        //return ColorPalette.navyColor
        default:
            log.warning("\(#function) : unrecognized status")
            return .inactive
        }
    }

    // MARK: - Public

    var nameColor: UIColor {
        return self.status.associatedColor
//        switch invoiceItem.status {
//        case InvoiceItemStatus.pending.rawValue:
//            return UIColor.lightGray
//        // Received
//        case InvoiceItemStatus.received.rawValue:
//            return UIColor.black
//        // Not Received
//        case InvoiceItemStatus.damaged.rawValue:
//            return ColorPalette.redColor
//        case InvoiceItemStatus.outOfStock.rawValue:
//            return ColorPalette.redColor
//        case InvoiceItemStatus.wrongItem.rawValue:
//            return ColorPalette.redColor
//        // Other
//        case InvoiceItemStatus.promo.rawValue:
//            return ColorPalette.navyColor
//        case InvoiceItemStatus.substitute.rawValue:
//            return ColorPalette.navyColor
//            
//        default:
//            log.warning("\(#function) : unrecognized status")
//            return UIColor.lightGray
//        }
    }
    var nameText: String {
        guard let name = item.name else {
            return "Error"
        }
        return name
    }

    //var packColor: UIColor { return .lightGray }
    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String { return "\(invoiceItem.quantity)" }

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String {
//        if self.status == .warning {
//            return ""
//        } else {
//            return invoiceItem.unit?.abbreviation ?? ""
//        }
        let quantity = invoiceItem.quantity
        if Double(quantity) > 0.0 {
            return invoiceItem.unit?.abbreviation ?? ""
        } else {
            return ""
        }
    }

    // MARK: - Lifecycle

    init(forInvoiceItem invoiceItem: InvoiceItem) {
        self.invoiceItem = invoiceItem
        guard let item = invoiceItem.item else {
            fatalError("Unable to get Item to configure cell")
        }
        self.item = item
    }

}
