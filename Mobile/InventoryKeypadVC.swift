
//
//  InventoryKeypadVC.swift
//  Playground
//
//  Created by Mathew Gacy on 10/10/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class InventoryKeypadVC: UIViewController {
    
    // MARK: Properties (TEMP)
    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    var currentIndex = 0
    
    
    /*
    // MARK: Properties
    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    //var items: [InventoryLocationItem] {
    var items: NSSet? {
        if let category = category {
            return category.items
        } else if let location = location {
            return location.items
            //} else {
            //return [InventoryLocationItem]()
        }
    }
    
    var currentIndex = 0
    var currentItem: InventoryLocationItem {
        return items[currentIndex]
    }
    
    let keypad = KeypadWithHistory()
    
    // MARK: - Display Outlets
    @IBOutlet weak var itemValue: UILabel!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemHistory: UILabel!
    
    // MARK: - Default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        /*
         // Update keypad with info from currentItem
         updateKeypad()
         
         // Update display
         updateDisplay()
         */
        updateForNewItem()
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
        
        // Update model with result of keypad
        updateModel()
        
        // Update display with updated model properties
        updateDisplay()
    }
    
    @IBAction func clearTapped(_ sender: AnyObject) {
        print("Tapped 'clear'")
        keypad.popItem()
        
        // Update model with result of keypad
        updateModel()
        
        // Update display with updated model properties
        updateDisplay()
    }
    
    @IBAction func decimalTapped(_ sender: AnyObject) {
        print("Tapped '.'")
        keypad.pushDecimal()
        
        // Update model with result of keypad
        updateModel()
        
        // Update display with updated model properties
        updateDisplay()
    }
    
    // MARK: - Uncertain
    
    @IBAction func addTapped(_ sender: AnyObject) {
        print("Tapped '+'")
        keypad.pushOperator()
        
        // Update model with result of keypad
        updateModel()
        
        // Update display with updated model properties
        updateDisplay()
        
    }
    
    @IBAction func decrementTapped(_ sender: AnyObject) {
        print("Tapped '-1'")
    }
    
    @IBAction func incrementTapped(_ sender: AnyObject) {
        print("Tapped '+1'")
        keypad.pushOperator()
        keypad.pushDigit(value: 1)
        keypad.pushOperator()
        
        // Update model with result of keypad
        updateModel()
        
        // Update display with updated model properties
        updateDisplay()
    }
    
    // MARK: - Item Navigation
    
    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            /*
             // Update keypad with info from new currentItem
             updateKeypad()
             
             // Update display with properties of new currentItem
             updateDisplay()
             */
            updateForNewItem()
        } else {
            // TODO: cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1
            /*
             // Update keypad with info from new currentItem
             updateKeypad()
             
             // Update display with properties of new currentItem
             updateDisplay()
             */
            updateForNewItem()
        } else {
            // TODO: cleanup?
            
            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }
    
    // MARK: - C
    
    func updateModel() {
        let keypadResult = keypad.evaluateHistory()
        currentItem.quantity = keypadResult
    }
    
    func updateKeypad() {
        /*
         if let itemQuantity = currentItem.quantity {
         keypad.currentNumber = String(format:"%.1f", itemQuantity)
         } else {
         keypad.currentNumber = ""
         }
         // TODO: update .stack with currentItem.history (?)
         //       - do we want to erase history with transition?
         //       - we don't want to save it (do we?)
         keypad.stack = []
         */
        keypad.updateNumber(currentItem.quantity)
    }
    
    // MARK: NEW
    
    func updateDisplay() {
        
        // TODO: currentItem.item.name
        //itemName.text = "Item: \(currentItem.itemID!)"
        
        let output = keypad.output()
        print("Output: \(output)")
        
        itemValue.text = output.display
        
        // TODO: currentItem.history
        itemHistory.text = output.history
        
    }
    
    func updateForNewItem() {
        // Update keypad with info from new currentItem
        keypad.updateNumber(currentItem.quantity)
        
        // Update display
        // TODO: currentItem.item.name
        //itemName.text = "Item: \(currentItem.itemID!)"
        updateDisplay()
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    */
}
