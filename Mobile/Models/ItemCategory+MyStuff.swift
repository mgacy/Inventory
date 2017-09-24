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

extension ItemCategory: Syncable {

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    public func update(context: NSManagedObjectContext, withJSON json: JSON) {
        // guard let json = json as? JSON else {
        //     log.error("\(#function) FAILED : SwiftyJSON"); return
        // }

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }
    }

}
