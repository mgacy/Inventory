//
//  VendorRep+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension VendorRep: NewSyncable {
    typealias RemoteType = RemoteRepresentative
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID
        firstName = record.firstName
        lastName = record.lastName
        email = record.email
        phone = record.phone
        // vendor relationship
    }

}
