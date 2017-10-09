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

extension ItemCategory: NewSyncable {
    typealias RemoteType = RemoteItemCategory
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }
    /*
    init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        self.setValue(record.syncIdentifier, forKey: self.remoteIdentifierName)
        self.update(with: record, in: context)
    }
     */
    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID = record.syncIdentifier
        name = record.name
    }

}
