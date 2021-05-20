//
//  CoreDataImporter.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/1/16.
//
//  Includes code from CDImporter.swift
//  Created by Tim Roadley on 5/10/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import CoreData
import UIKit

class CoreDataImporter {

    // TODO: should this really handle setting defaults?
    /*
    private let defaults: UserDefaults

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - 

    func isDefaultDataAlreadyPreloaded() -> Bool {
        // TODO: use getter?
        return defaults.bool(forKey: "isPreloaded")
    }
    */

    func preloadData(in context: NSManagedObjectContext) -> Bool {
        // Retrieve data from the source file
        guard let asset = NSDataAsset(name: "units", bundle: Bundle.main) else {
            log.error("Invalid filename.")
            return false
        }

        let decoder = JSONDecoder()
        do {
            let units = try decoder.decode([RemoteUnit].self, from: asset.data)
            Unit.sync(with: units, in: context)
        } catch {
            log.error("\(#function) FAILED : error trying to decode Unit data")
        }

        if context.saveOrRollback() == true {
            //defaults.set(true, forKey: "isPreloaded")
            return true
        } else {
            log.error("\(#function) FAILED : unable to load Unit data")
            return false
        }
    }

}
