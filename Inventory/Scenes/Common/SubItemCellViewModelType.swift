//
//  SubItemCellViewModelType.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/13/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

protocol SubItemCellViewModelType {
    //associatedtype Object: NSManagedObject
    var nameText: String { get }
    var nameColor: UIColor { get }
    var packText: String { get }
    var packColor: UIColor { get }
    var quantityText: String { get }
    var quantityColor: UIColor { get }
    var unitText: String { get }
    var unitColor: UIColor { get }

    //init(for: Object)
}

// MARK: Default Implementations

extension SubItemCellViewModelType {
    var packColor: UIColor { return UIColor.lightGray }
}
