//
//  Item+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/1/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension Item {

    static func withID(_ id: Int, fromContext context: NSManagedObjectContext) -> Item? {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
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
        self.update(context: context, withJSON: json)
    }

    func update(context: NSManagedObjectContext, withJSON json: JSON) {
        
        // Properties
        if let remoteID = json["id"].int {
            self.remoteID = Int32(remoteID)
        }
        if let name = json["name"].string {
            self.name = name
        }
        if let packSize = json["pack_size"].int {
            self.packSize = Int16(packSize)
        }
        if let subSize = json["sub_size"].int {
            self.subSize = Int16(subSize)
        }

        //if let categoryID = json["category_id"].int {
        //    self.categoryID = Int32(categoryID)
        //}

        // TODO - implement:
        // active
        // shelfLife
        // sku
        // vendorItemID
        
        // Relationships
        // if let categoryID = json["category"]["id"].int { }
        if let vendorID = json["vendor"]["id"].int {
            
            if let vendor = fetchEntityByID(entityType: Vendor.self, context: context, id: vendorID) {
                //print("Found Vendor: \(vendor)")
                self.vendor = vendor
            } else {
                let newVendor = Vendor(context: context)
                newVendor.remoteID = Int32(vendorID)
                
                if let vendorName = json["vendor"]["name"].string {
                    newVendor.name = vendorName
                }
            }

        }

        if let inventoryUnitID = json["inventory_unit"]["id"].int {
            self.inventoryUnit = fetchUnit(context: context, id: inventoryUnitID)
        }
        if let purchaseUnitID = json["purchase_unit"]["id"].int {
            self.purchaseUnit = fetchUnit(context: context, id: purchaseUnitID)
        }
        if let purchaseSubUnitID = json["purchase_sub_unit"]["id"].int {
            self.purchaseSubUnit = fetchUnit(context: context, id: purchaseSubUnitID)
        }
        if let subUnitID = json["sub_unit"]["id"].int {
            self.subUnit = fetchUnit(context: context, id: subUnitID)
        }

        // TODO - implement:
        // category
        // parUnit
        // store
    }

    // MARK: - Serialization

    // MARK: - Fetch Object

    func fetchEntities<T: NSManagedObject>(entityType: T.Type, fromManagedObjectContext moc: NSManagedObjectContext, predicate: NSPredicate) -> [T] {
        let classNameComponents: [String] = entityType.description().components(separatedBy: ".")
        let className = classNameComponents[classNameComponents.count-1]
        
        let fetchRequest = NSFetchRequest<T>(entityName: className)
        
        var searchResults = [T]()
        do {
            searchResults = try moc.fetch(fetchRequest)
        } catch {
            print("Error with request: \(error)")
        }
        
        return searchResults
    }
    
    func fetchEntityByID<T: NSManagedObject>(entityType: T.Type, context moc: NSManagedObjectContext, id: Int) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
    
        do {
            let searchResults = try moc.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find entity with id: \(id)")
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

    private func fetchUnit(context moc: NSManagedObjectContext, id: Int) -> Unit? {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let searchResults = try moc.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return nil
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches for Unit with id: \(id) - \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        
        return nil
    }

}
