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

    enum UnitRelationship {
        case inventoryUnit
        case parUnit
        case purchaseUnit
        case subUnit
    }

    // MARK: - Lifecycle

    convenience init(context: NSManagedObjectContext, json: JSON) {
        self.init(context: context)

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

        if let categoryID = json["category_id"].int {
            self.categoryID = Int32(categoryID)
        }
        
        // TODO - implement:
        // active
        // shelfLife
        // sku
        // vendorItemID
        
        // Relationships
        // if let categoryID = json["category"]["id"].int { }
        if let vendorID = json["vendor"]["id"].int {
            /*
            self.vendor = genericFetch(
                Vendor, context: context,
                predicate: NSPredicate(format: "remoteID == \(Int32(vendorID))"))
            */
            
            self.vendor = genericFetch(
                Vendor, context: context,
                predicateString: "remoteID == \(Int32(vendorID))")
        }

        if let inventoryUnitID = json["inventory_unit"]["id"].int {
            self.inventoryUnit = fetchUnit(context: context, id: inventoryUnitID)
        }
        if let purchaseUnitID = json["purchase_unit"]["id"].int {
            self.purchaseUnit = fetchUnit(context: context, id: purchaseUnitID)
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

    private func genericFetch<T: NSManagedObject>(_ t: T, context: NSManagedObjectContext, predicate: NSPredicate) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate

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

    private func genericFetchWithString<T: NSManagedObject>(_ t: T, context: NSManagedObjectContext, predicateString: String) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: predicateString)
        
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
    
    private func fetchUnit(context: NSManagedObjectContext, id: Int) {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        
        do {
            let unit: Unit
            let searchResults = try context.fetch(request)
            
            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return
            case 1:
                return searchResults[0]
            default:
                print("Found multiple matches for Unit with id: \(id) - \(searchResults)")
                return searchResults[0]
            }
            
        } catch {
            print("Error with request: \(error)")
        }
    }
    
    //private func fetchStore(context: NSManagedObjectContext, id: Int) {}

    //private func fetchVendor(context: NSManagedObjectContext, id: Int) { }

    // MARK: - Fetch Object + Establish Relationship
    
    private func fetchUnit(context: NSManagedObjectContext, id: Int, relationship: UnitRelationship) {
        let request: NSFetchRequest<Unit> = Unit.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")

        do {
            let unit: Unit
            let searchResults = try context.fetch(request)

            switch searchResults.count {
            case 0:
                print("PROBLEM - Unable to find Unit with id: \(id)")
                return
            case 1:
                unit = searchResults[0]
            default:
                print("Found multiple matches for Unit with id: \(id) - \(searchResults)")
                unit = searchResults[0]
            }

            // Establish relationship
            switch relationship {
            case .inventoryUnit:
                self.inventoryUnit = unit
            case .parUnit:
                self.parUnit = unit
            case .purchaseUnit:
                self.purchaseUnit = unit
            case .subUnit:
                self.subUnit = unit
            }

        } catch {
            print("Error with request: \(error)")
        }
    }

}
