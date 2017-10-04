//
//  ItemCategory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/15/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

// MARK: - NEW

extension ItemCategory: NewSyncable {
    typealias RemoteType = RemoteItemCategory
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID = Int32(record.remoteID)
        name = record.name
    }

}
