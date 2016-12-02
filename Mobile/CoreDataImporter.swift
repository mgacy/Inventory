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
        // let asset = NSDataAsset(name: "units", bundle: Bundle.main)
        // if let path = Bundle.main.path(forResource: "assets/units", ofType: "json") {
        if let path = Bundle.main.path(forResource: "units", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonArray = JSON(data: data)
                if jsonArray != JSON.null {
                    //print("jsonData:\(jsonArray)")

                    //let managedObjectContext = CoreDataStack.shared.viewContext
                    let managedObjectContext = CoreDataStack.shared.backgroundContext

                    for (_, unitJSON):(String, JSON) in jsonArray {
                        //print("\(unitJSON)")
                        let unit = Unit(context: managedObjectContext, json: unitJSON)
                        print("\(unit)")
                    }

                } else {
                    print("Could not get json from file, make sure that file contains valid json.")
                }
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print("Invalid filename/path.")
        }
    }

}
