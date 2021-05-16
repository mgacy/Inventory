//
//  ItemCategory+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/15/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension ItemCategory: Syncable {
    typealias RemoteType = RemoteItemCategory
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        //self.setValue(record.syncIdentifier, forKey: self.remoteIdentifierName)
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID = record.syncIdentifier
        name = record.name
    }

}
