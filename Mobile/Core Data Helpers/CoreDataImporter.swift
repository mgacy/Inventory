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

import Foundation
import UIKit
import CoreData
import SwiftyJSON

class CoreDataImporter {

    static let shared = CoreDataImporter()

    func isDefaultDataAlreadyPreloaded() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "isPreloaded")
    }

    func preloadData() {

        // Retrieve data from the source file
        if let asset = NSDataAsset(name: "units", bundle: Bundle.main) {

            let data = asset.data
            let jsonArray = JSON(data: data)
            if jsonArray != JSON.null {

                let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                //let managedObjectContext = CoreDataStack.shared.viewContext
                //let managedObjectContext = CoreDataStack.shared.backgroundContext

                for (_, unitJSON):(String, JSON) in jsonArray {
                    _ = Unit(context: managedObjectContext, json: unitJSON)
                }

            } else {
                log.error("Could not get json from file, make sure that file contains valid json.")
            }

        } else {
            log.error("Invalid filename.")
        }
    }

}
