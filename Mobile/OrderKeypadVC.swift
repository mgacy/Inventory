//
//  OrderKeypadVC.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class OrderKeypadVC: UIViewController {

    // MARK: Properties
    
    var parentObject: Order!
    var currentIndex = 0
    
    var items: [OrderItem] {
        let request: NSFetchRequest<OrderItem> = OrderItem.fetchRequest()
        request.predicate = NSPredicate(format: "order == %@", parentObject)
        
        let sortDescriptor = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            let searchResults = try managedObjectContext?.fetch(request)
            return searchResults!
            
        } catch {
            print("Error with request: \(error)")
        }
        return [OrderItem]()
    }
    
    var currentItem: OrderItem {
        return items[currentIndex]
    }
    
    typealias keypadOutput = (total: Double?, display: String)
    let keypad = Keypad()
    
    // CoreData
    var managedObjectContext: NSManagedObjectContext?
    
    // MARK: - Display Outlets
    
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var par: UILabel!
    @IBOutlet weak var onHand: UILabel!
    @IBOutlet weak var minOrder: UILabel!
    @IBOutlet weak var caseSize: UILabel!
    @IBOutlet weak var order: UILabel!
    @IBOutlet weak var orderUnit: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        update(newItem: true)
        
        print("currentItem: \(currentItem)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Keypad
    
    /*
     TODO: should any call to keypad return (quantity: Double, history: String) so
     that those can then be passed both to currentItem and the display?
     */
    
    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        print("Tapped '\(digit)'")
        guard let number = Int(digit!) else { return }
        keypad.pushDigit(value: number)
        
        update()
    }
    
    @IBAction func clearTapped(_ sender: AnyObject) {
        print("Tapped 'clear'")
        keypad.popItem()
        
        update()
    }
    
    @IBAction func decimalTapped(_ sender: AnyObject) {
        print("Tapped '.'")
        keypad.pushDecimal()
        
        update()
    }
    
    // MARK: - Units
    
    @IBAction func packTapped(_ sender: AnyObject) {
    
    }
    
    @IBAction func unitTapped(_ sender: AnyObject) {
    
    }
    
    // MARK: - Item Navigation
    
    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            
            update(newItem: true)
        } else {
            // TODO - cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1
            
            update(newItem: true)
        } else {
            // TODO - cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    // MARK: - C
    
    func updateModel() {
        
//        if let keypadResult = keypad.evaluateHistory() {
//            currentItem.quantity = keypadResult as NSNumber?
//        } else {
//            currentItem.quantity = nil
//        }
        
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
    
    // MARK: NEW
    
    func updateDisplay() {
        
        // TODO - guard currentItem
        
        // Item.name
        // Item.name
        /*
        guard let item = currentItem.item else {
            itemName.text = "Error (1)"
            return
        }
        guard let name = item.name else {
            itemName.text = "Error (2)"
            return
        }
        */
        guard let name = currentItem.name else {
            itemName.text = "Error (1)"
            return
        }
        itemName.text = name
        
        
        // Item.minOrder
        minOrder.text = "\(currentItem.minOrder) \(currentItem.minOrderUnit?.abbreviation)"
        
        // Item.caseSize
        // Item.par
        par.text = "\(currentItem.par) \(currentItem.item?.parUnit?.abbreviation)"
        
        // Item.order
        order.text = "\(currentItem.quantity)"
        
        // Item.orderUnit
        orderUnit.text = currentItem.orderUnit?.abbreviation
        
        
        /*
        
         @IBOutlet weak var itemName: UILabel!
         @IBOutlet weak var par: UILabel!
         @IBOutlet weak var onHand: UILabel!
         @IBOutlet weak var minOrder: UILabel!
         @IBOutlet weak var caseSize: UILabel!
         @IBOutlet weak var order: UILabel!
         @IBOutlet weak var orderUnit: UILabel!
         
         let output = keypad.output()
        print("Output: \(output)")
        
        // Item.quantity
        itemValue.text = output.display
        if output.total != nil {
            itemValue.textColor = UIColor.black
        } else {
            itemValue.textColor = UIColor.lightGray
        }
        
        itemHistory.text = output.history
        
        // Item.pack
        
        // Item.unit
        */
    }
    
    func updateForNewItem() {
        // print("updateForNewItem: \(currentItem.item?.name) - \(currentItem)")
        
        // Update keypad with info from new currentItem
        //keypad.updateNumber(currentItem.quantity as Int?)
        
        // Update display
        updateDisplay()
    }

    
    // MARK: - NEW
    
    func update(newItem: Bool = false) {
        
        let output: keypadOutput
        
        switch newItem {
        case true:
            // Update keypad with quantity of new currentItem
            keypad.updateNumber(currentItem.quantity as Double?)
            output = keypad.outputB()
        case false:
            // Update model with output of keyapd
            output = keypad.outputB()
            
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
    
    func updateDisplay(item: OrderItem, keypadOutput: keypadOutput) {
        
        
        
        
        
        
        // TODO - guard currentItem
        
        // Item.name
        // Item.name
        /*
         guard let item = currentItem.item else {
         itemName.text = "Error (1)"
         return
         }
         guard let name = item.name else {
         itemName.text = "Error (2)"
         return
         }
         */
        guard let name = currentItem.name else {
            itemName.text = "Error (1)"
            return
        }
        itemName.text = name
        
        
        // Item.minOrder
        minOrder.text = "\(currentItem.minOrder) \(currentItem.minOrderUnit?.abbreviation)"
        
        // Item.caseSize
        // Item.par
        par.text = "\(currentItem.par) \(currentItem.item?.parUnit?.abbreviation)"
        
        // Item.order
        order.text = "\(currentItem.quantity)"
        
        // Item.orderUnit
        orderUnit.text = currentItem.orderUnit?.abbreviation
        
        /*
         
         @IBOutlet weak var itemName: UILabel!
         @IBOutlet weak var par: UILabel!
         @IBOutlet weak var onHand: UILabel!
         @IBOutlet weak var minOrder: UILabel!
         @IBOutlet weak var caseSize: UILabel!
         @IBOutlet weak var order: UILabel!
         @IBOutlet weak var orderUnit: UILabel!
         
         let output = keypad.output()
         print("Output: \(output)")
         
         // Item.quantity
         itemValue.text = output.display
         if output.total != nil {
         itemValue.textColor = UIColor.black
         } else {
         itemValue.textColor = UIColor.lightGray
         }
         
         itemHistory.text = output.history
         
         // Item.pack
         
         // Item.unit
         */
        
        
        
    }
    
}
