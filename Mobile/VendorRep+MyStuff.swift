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

extension VendorRep {

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }
}

extension VendorRep: Syncable {

    public func update(context: NSManagedObjectContext, withJSON json: Any) {
        guard let json = json as? JSON else {
            log.error("\(#function) FAILED : SwiftyJSON"); return
        }

        // Properties
        /// TODO: remoteID is required
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let firstName = json["first_name"].string {
            self.firstName = firstName
        }
        if let lastName = json["last_name"].string {
            self.lastName = lastName
        }
        if let email = json["email"].string {
            self.email = email
        }
        if let phone = json["phone"].string {
            self.phone = phone
        }
    }

}
