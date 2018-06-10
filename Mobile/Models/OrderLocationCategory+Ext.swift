//
//  OrderLocationCategory+Ext.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/23/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import CoreData

extension OrderLocationCategory {
    typealias RemoteType = RemoteItemCategory
    //typealias RemoteIdentifierType = Int32

    //var remoteIdentifier: Int32 { return self.remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        //remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID
        name = record.name
        //locationType

        // Relationships
        //items?
    }

}
