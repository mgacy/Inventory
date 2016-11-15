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

extension Vendor {
    
    static func withID(_ id: Int, fromContext context: NSManagedObjectContext) -> Vendor? {
        let request: NSFetchRequest<Vendor> = Vendor.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
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
    
    // MARK: - Lifecycle
    
    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)
        
        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let name = json["name"].string {
            self.name = name
        }

        // TODO - create separate VendorRep object
        
    }
    
}
