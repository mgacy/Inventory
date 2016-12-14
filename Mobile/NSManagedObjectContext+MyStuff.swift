//
//  NSManagedObjectContext+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/14/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    // NOTE - this requires (1) entity has remoteID and (2) type is Int32
    // TODO - make T require objects conforming to protocol specifying the above requirements?
    public func fetchWithRemoteID<T : NSManagedObject>(_ entity: T.Type, withID id: Int) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = NSPredicate(format: "remoteID == \(Int32(id))")
        request.fetchLimit = 2
        
        do {
            let fetchResults = try self.fetch(request)
            
            switch fetchResults.count {
            case 0:
                //print("Found 0 matches for remoteID \(id)")
                return nil
            case 1:
                return fetchResults[0]
            default:
                print("\(#function) FAILED: found multiple matches for remoteID \(id): \(fetchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }
            
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
    public func fetchSingleEntity<T : NSManagedObject>(_ entity: T.Type, matchingPredicate predicate: NSPredicate) -> T? {
        let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        request.predicate = predicate
        request.fetchLimit = 2
        
        do {
            let fetchResults = try self.fetch(request)
            
            switch fetchResults.count {
            case 0:
                return nil
            case 1:
                return fetchResults[0]
            default:
                //print("Found multiple matches: \(searchResults)")
                fatalError("Returned multiple objects, expected max 1")
            }
        
        } catch {
            print("Error with request: \(error)")
        }
        return nil
    }
    
    // http://codereview.stackexchange.com/questions/147005/swift-3-generic-fetch-request-extension
    func fetchEntities<T: NSManagedObject>(_ entityClass: T.Type, sortBy: [NSSortDescriptor]? = nil, matchingPredicate predicate: NSPredicate? = nil) throws -> [T] {
        var request: NSFetchRequest<NSFetchRequestResult>
        
        if #available(iOS 10.0, *) {
            request = entityClass.fetchRequest()
        } else {
            let entityClassName = NSStringFromClass(entityClass)
            let entityName = entityClassName.components(separatedBy: ".").last ?? entityClassName
            request = NSFetchRequest(entityName: entityName)
        }
        
        var fetchRequestError: Error?
        request.returnsObjectsAsFaults = false
        
        if let predicate = predicate {
            request.predicate = predicate
        }
        if let sortBy = sortBy {
            request.sortDescriptors = sortBy
        }
        
        var fetchedResult: [T]?
        
        do {
            fetchedResult = try self.fetch(request) as? [T]
        }
        catch let error {
            fetchRequestError = error
            //print(fetchRequestError)
        }
        
        guard let entityArray = fetchedResult else {
            throw fetchRequestError!
        }
        
        return entityArray
    }
    
}
