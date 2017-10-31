//
//  Vendor+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import CoreData

extension Vendor: NewSyncable {
    typealias RemoteType = RemoteVendor
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        remoteID = Int32(record.remoteID)
        name = record.name

        /// TODO: create separate VendorRep object
        if let repRecord = record.rep {
            let rep = VendorRep.updateOrCreate(with: repRecord, in: context)
            rep.vendor = self
        }
    }

}
