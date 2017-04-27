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

extension Unit: SyncableItem {
        
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        self.update(context: context, withJSON: json)
    }

    func update(context: NSManagedObjectContext, withJSON json: JSON) {
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