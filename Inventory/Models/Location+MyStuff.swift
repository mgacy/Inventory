//
//  Location+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/19/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import Foundation

@objc enum LocationType: Int16 {
    case category   = 0
    case item       = 1

    // TODO: see `Invoice+MyStuff.swift`
    //static func asString(raw: Int16) -> String? {}

    //init?(string: String) {}

    init(recordStatus locationType: RemoteLocationType) {
        switch locationType {
        case .category: self = .category
        case .item: self = .item
        }
    }
}
