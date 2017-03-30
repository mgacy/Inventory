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

extension Vendor: SyncableItem {
    
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }
    
    public func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }

        // TODO - create separate VendorRep object
    }

}
