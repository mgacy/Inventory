//
//  InvoiceKeypadVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/31/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InvoiceKeypadVC: UIViewController {

    // MARK: Properties
    
    var parentObject: Invoice!
    var currentIndex = 0
    
    var items: [InvoiceItem] {
        let request: NSFetchRequest<InvoiceItem> = InvoiceItem.fetchRequest()
        request.predicate = NSPredicate(format: "invoice == %@", parentObject)
        
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let searchResults = try managedObjectContext?.fetch(request)
            return searchResults!
            
        } catch {
            print("Error with request: \(error)")
        }
        return [InvoiceItem]()
    }
    
    var currentItem: InvoiceItem {
        //print("currentItem: \(items[currentIndex])")
        return items[currentIndex]
    }
    
    typealias keypadOutput = (total: Double?, display: String)
    let keypad = Keypad()
    
    // CoreData
    var managedObjectContext: NSManagedObjectContext?
    
    var numberFormatter: NumberFormatter?
    
    // MARK: - Display Outlets
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup numberFormatter
        numberFormatter = NumberFormatter()
        guard let numberFormatter = numberFormatter else { return }
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2
        
        update(newItem: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - C
    
    func update(newItem: Bool = false) {}
    
    func updateDisplay(item: InvoiceItem, keypadOutput: keypadOutput) {}

}
