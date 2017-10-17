//
//  Unit+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension Unit: Syncable {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {
        // guard let json = json as? JSON else {
        //     log.error("\(#function) FAILED : SwiftyJSON"); return
        // }

        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let abbreviation = json["abbreviation"].string {
            self.abbreviation = abbreviation
        }
    }

}

extension Unit: NewSyncable {
    typealias RemoteType = RemoteUnit
    typealias RemoteIdentifierType = Int32

    var remoteIdentifier: RemoteIdentifierType { return remoteID }

    convenience init(with record: RemoteType, in context: NSManagedObjectContext) {
        self.init(context: context)
        remoteID = record.syncIdentifier
        update(with: record, in: context)
    }

    func update(with record: RemoteType, in context: NSManagedObjectContext) {
        //remoteID = record.syncIdentifier
        name = record.name
        abbreviation = record.abbreviation
    }

}
