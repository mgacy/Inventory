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

    //convenience init(context: NSManagedObjectContext, representation: Any)
    //func update(with json: Any, in context: NSManagedObjectContext)
    func update(context: NSManagedObjectContext, withJSON json: Any)
}

// MARK: - ManagedSyncable
protocol ManagedSyncable: Managed, Syncable {}

extension ManagedSyncable where Self: NSManagedObject {

    static func findOrCreate(withID id: Int32, withJSON json: Any, in context: NSManagedObjectContext) -> Self {
        let predicate = NSPredicate(format: "remoteID == \(id)")

        /// TODO: improve this ugly mess
        /*
         if let object: Self = findOrFetch(in: context, matching: predicate) {
         object.update(context: context, withJSON: json)
         } else {
         let object: Self = context.insertObject()
         object.update(context: context, withJSON: json)
         }
         return object
         */

        guard let obj: Self = findOrFetch(in: context, matching: predicate) else {
            //log.debug("Creating \(Self.self) \(id)")
            let newObj: Self = context.insertObject()
            newObj.update(context: context, withJSON: json)
            return newObj
        }
        //log.debug("Updating \(Self.self) \(id)")
        obj.update(context: context, withJSON: json)
        return obj
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
