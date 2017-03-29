//
//  InvoiceCollection+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension InvoiceCollection {
    
    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON, uploaded: Bool = false) {
        self.init(context: context)

        // Set properties
        if let date = json["date"].string {
            self.date = date
        } else {
            self.date = Date().shortDate
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        self.uploaded = uploaded

        // Add Invoices
        if let invoices = json["invoices"].array {
            for invoiceJSON in invoices {
                _ = Invoice(context: context, json: invoiceJSON, collection: self, uploaded: uploaded)
            }
        }
    }
    
    // MARK: - Serialization
    
    func serialize() -> [String: Any]? {
        var myDict = [String: Any]()
        
        // TODO - handle conversion from NSDate to string
        myDict["date"] = self.date
        myDict["store_id"] = self.storeID
        
        return myDict
    }
    
    // MARK: - Update Existing
    
    func updateExisting(context: NSManagedObjectContext, json: JSON) {
        
        // Iterate over Invoices
        for (_, item) in json {
            _ = Invoice(context: context, json: item, collection: self, uploaded: true)
        }
    }
    
    // MARK: -
    
    static func fetchByDate(context: NSManagedObjectContext, date: String) -> InvoiceCollection? {
        //let predicate = NSPredicate(format: "date == %@", date)
        //return context.fetchSingleEntity(InvoiceCollection.self, matchingPredicate: predicate)
        
        let request: NSFetchRequest<InvoiceCollection> = InvoiceCollection.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date)
        
        do {
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches: \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
}

extension InvoiceCollection: SyncableCollection {

    func update(context: NSManagedObjectContext, withJSON json: JSON) {

        // Set properties
        if let date = json["date"].string {
            self.date = date
        }
        if let storeID = json["store_id"].int32 {
            self.storeID = storeID
        }
        //self.uploaded = uploaded
    }

}
