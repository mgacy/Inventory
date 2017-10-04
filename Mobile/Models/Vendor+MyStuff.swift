//
//  Vendor+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension Vendor: NewSyncable {
    typealias RemoteType = RemoteVendor
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

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
