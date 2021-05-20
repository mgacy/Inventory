//
//  ItemCellViewModel.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/7/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

struct ItemCellViewModel: SubItemCellViewModelType {
    private var item: Item
    private var status: ItemStatus {
        return .normal
    }

    // MARK: - Public

    var nameColor: UIColor {
        return self.status.associatedColor
    }
    var nameText: String {
        return item.name ?? "Error"
    }

    //var packColor: UIColor { return .lightGray }
    var packText: String { return item.packDisplay }

    var quantityColor: UIColor { return self.status.associatedColor }
    var quantityText: String { return "" }

    var unitColor: UIColor { return self.status.associatedColor }
    var unitText: String { return "" }

    // MARK: - Lifecycle

    init(forItem item: Item) {
        self.item = item
    }

}
