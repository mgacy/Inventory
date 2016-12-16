//
//  Syncable.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/15/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc public protocol Syncable: class {

    // https://gist.github.com/capttaco/adb38e0d37fbaf9c004e
    // typealias SyncableType: NSManagedObject = Self

    var remoteID: Int32 { get set }
    var name: String? { get set }

    //func update(context: NSManagedObjectContext, withJSON json: JSON)

}

extension Syncable {

    // TODO - rename updateWithJSON / updateFromJSON?
    func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
        if let name = json["name"].string {
            self.name = name
        }
    }
    
}
