//
//  NSManagedObjectContext+Managed.swift
//  Mobile
//
//  Created by Florian on 07/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {

    func insertObject<T: NSManagedObject>() -> T where T: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self) as? T else {
            fatalError("Wrong object type")
        }
        return obj
    }

}
