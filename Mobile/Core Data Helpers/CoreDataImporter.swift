//
//  CoreDataImporter.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/1/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//
//  Includes code from CDImporter.swift
//  Created by Tim Roadley on 5/10/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import CoreData
import SwiftyJSON

class CoreDataImporter {

    /// TODO: should this really handle setting defaults?
    /*
    private let defaults: UserDefaults

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - 

    func isDefaultDataAlreadyPreloaded() -> Bool {
        /// TODO: use getter?
        return defaults.bool(forKey: "isPreloaded")
    }
    */

    func preloadData(in context: NSManagedObjectContext) -> Bool {
        // Retrieve data from the source file
        guard let asset = NSDataAsset(name: "units", bundle: Bundle.main) else {
            log.error("Invalid filename.")
            return false
        }
        let jsonArray = JSON(data: asset.data)
        guard jsonArray != JSON.null else {
            log.error("Could not get json from file, make sure that file contains valid json.")
            return false
        }

        for (_, unitJSON):(String, JSON) in jsonArray {
            _ = Unit(context: context, json: unitJSON)
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
