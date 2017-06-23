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

extension Vendor: Syncable {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    public func update(context: NSManagedObjectContext, withJSON json: Any) {
        guard let json = json as? JSON else {
            log.error("\(#function) FAILED : SwiftyJSON"); return
        }

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }

        // Relationships
        if let repJSON = json["rep"].dictionary, let repID = json["rep"]["id"].int32 {
            let repJSON = JSON(repJSON)
            let rep = VendorRep.findOrCreate(withID: repID, withJSON: repJSON, in: context)
            rep.vendor = self
        }
    }

}
