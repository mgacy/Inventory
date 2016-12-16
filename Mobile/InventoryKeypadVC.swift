//
//  InventoryKeypadVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/10/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryKeypadVC: UIViewController {
    
    // MARK: Properties

    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    var currentIndex = 0

    var items: [InventoryLocationItem] {
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()
        
        if let parentLocation = self.location {
            request.predicate = NSPredicate(format: "location == %@", parentLocation)
            let sortDescriptor = NSSortDescriptor(key: "position", ascending: true)
            request.sortDescriptors = [sortDescriptor]

        } else if let parentCategory = self.category {
            request.predicate = NSPredicate(format: "category == %@", parentCategory)
            let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
            request.sortDescriptors = [sortDescriptor]

        } else {
            print("\nPROBLEM - Unable to add predicate\n")
            return [InventoryLocationItem]()
        }
        
        do {
            let searchResults = try managedObjectContext?.fetch(request)
            return searchResults!

        } catch {
            print("Error with request: \(error)")
        }
        return [InventoryLocationItem]()
    }
    
    var currentItem: InventoryLocationItem {
        return items[currentIndex]
    }
    
    typealias keypadOutput = (history: String, total: Double?, display: String)
    let keypad = KeypadWithHistory()
    
    // CoreData
    var managedObjectContext: NSManagedObjectContext?
    
    // MARK: - Display Outlets
    @IBOutlet weak var itemValue: UILabel!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemHistory: UILabel!
    @IBOutlet weak var itemPack: UILabel!
    @IBOutlet weak var itemUnit: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        update(newItem: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Keypad
    
    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        print("Tapped '\(digit)'")
        guard let number = Int(digit!) else { return }
        keypad.pushDigit(value: number)
        
        // Update model and display with result of keypad
        update()
    }
    
    @IBAction func clearTapped(_ sender: AnyObject) {
        print("Tapped 'clear'")
        keypad.popItem()
        
        // Update model and display with result of keypad
        update()
    }
    
    @IBAction func decimalTapped(_ sender: AnyObject) {
        print("Tapped '.'")
        keypad.pushDecimal()
        
        // Update model and display with result of keypad
        update()
    }
    
    // MARK: - Uncertain
    
    @IBAction func addTapped(_ sender: AnyObject) {
        print("Tapped '+'")
        keypad.pushOperator()
        
        // Update model and display with result of keypad
        update()
    }
    
    @IBAction func decrementTapped(_ sender: AnyObject) {
        print("Tapped '-1'")
    }
    
    @IBAction func incrementTapped(_ sender: AnyObject) {
        print("Tapped '+1'")
        keypad.pushOperator()
        keypad.pushDigit(value: 1)
        keypad.pushOperator()
        
        // Update model and display with result of keypad
        update()
    }
    
    // MARK: - Item Navigation
    
    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            
            // Update keypad and display with new currentItem
            update(newItem: true)
            
        } else {
            // TODO: cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1
            
            // Update keypad and display with new currentItem
            update(newItem: true)
            
        } else {
            // TODO: cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    // MARK: - View
        
    func update(newItem: Bool = false) {
        let output: keypadOutput
        
        switch newItem {
        case true:
            // Update keypad with quantity of new currentItem
            keypad.updateNumber(currentItem.quantity as Double?)
            output = keypad.output()
        case false:
            // Update model with output of keyapd
            output = keypad.output()
            
            if let keypadResult = output.total {
                currentItem.quantity = keypadResult as NSNumber?
            } else {
                currentItem.quantity = nil
            }
            
            // Save the context.
            let context = self.managedObjectContext!
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        
        updateDisplay(item: currentItem, keypadOutput: output)
    }

    // func updateDisplay(item: InventoryLocationItem, history: String, total: Double?, display: String) {}
    func updateDisplay(item: InventoryLocationItem, keypadOutput: keypadOutput) {

        // Item.quantity
        itemValue.text = keypadOutput.display
        if keypadOutput.total != nil {
            itemValue.textColor = UIColor.black
        } else {
            itemValue.textColor = UIColor.lightGray
        }
        
        itemHistory.text = keypadOutput.history
        
        // Item.name
        guard let inventoryItem = currentItem.item else {
            itemName.text = "Error (1)"; return
        }
        guard let name = inventoryItem.name else {
            itemName.text = "Error (2)"; return
        }
        itemName.text = name
        
        // Item.pack
        guard let item = inventoryItem.item else { return }
        itemPack.text = item.packDisplay

        // Item.unit
        itemUnit.text = "\(item.inventoryUnit?.abbreviation ?? "")"
    }

}
