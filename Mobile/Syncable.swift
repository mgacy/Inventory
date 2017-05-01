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

// MARK: - Syncable
@objc public protocol Syncable {

    // https://gist.github.com/capttaco/adb38e0d37fbaf9c004e
    //associatedtype SyncableType: NSManagedObject = Self

    var remoteID: Int32 { get set }

    // func update(context: NSManagedObjectContext, withJSON json: JSON)

}

extension Syncable where Self : NSManagedObject {

    /// TODO: rename updateWithJSON / updateFromJSON?
    func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Properties
        if let remoteID = json["id"].int32 {
            self.remoteID = remoteID
        }
    }

}
// MARK: - SyncableCollection
@objc public protocol SyncableCollection {

    var date: String? { get set }
    var storeID: Int32 { get set }
    var uploaded: Bool { get set }

}

extension SyncableCollection where Self : NSManagedObject {

    func update(context: NSManagedObjectContext, withJSON json: JSON) {
        if let date = json["date"].string {
            self.date = date
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        //self.uploaded = uploaded
    }

    func update(context: NSManagedObjectContext, withJSON json: JSON, uploaded: Bool) {
        if let date = json["date"].string {
            self.date = date
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        self.uploaded = uploaded
    }

}
