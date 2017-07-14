//
//  InventoryKeypadViewController.swift
//  Playground
//
//  Created by Mathew Gacy on 10/10/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import CoreData

class InventoryKeypadViewController: UIViewController {

    // MARK: Properties

    var category: InventoryLocationCategory?
    var location: InventoryLocation?
    var currentIndex = 0

    var items: [InventoryLocationItem] {
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()

        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        if let parentLocation = self.location {
            request.predicate = NSPredicate(format: "location == %@", parentLocation)
        } else if let parentCategory = self.category {
            request.predicate = NSPredicate(format: "category == %@", parentCategory)
        } else {
            log.error("PROBLEM : Unable to add predicate to InventoryLocationItem fetch request")
            return [InventoryLocationItem]()
        }

        do {
            let searchResults = try managedObjectContext?.fetch(request)
            return searchResults!

        } catch {
            log.error("Error with InventoryLocationItem fetch request: \(error)")
        }
        return [InventoryLocationItem]()
    }

    var currentItem: InventoryLocationItem {
        return items[currentIndex]
    }

    typealias KeypadOutput = (history: String, total: Double?, display: String)
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
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Keypad

    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        //log.verbose("Tapped '\(digit)'")
        guard let number = Int(digit!) else { return }
        keypad.pushDigit(value: number)

        // Update model and display with result of keypad
        update()
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        keypad.popItem()
        update()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        keypad.pushDecimal()
        update()
    }

    // MARK: - Uncertain

    @IBAction func addTapped(_ sender: AnyObject) {
        keypad.pushOperator()
        update()
    }

    @IBAction func decrementTapped(_ sender: AnyObject) {
        //log.verbose("Tapped '-1'")
    }

    @IBAction func incrementTapped(_ sender: AnyObject) {
        keypad.pushOperator()
        keypad.pushDigit(value: 1)
        keypad.pushOperator()
        update()
    }

    // MARK: - Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            // Update keypad and display with new currentItem
            update(newItem: true)
        } else {
            /// TODO: cleanup?
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1
            // Update keypad and display with new currentItem
            update(newItem: true)
        } else {
            /// TODO: cleanup?
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: - View

    func update(newItem: Bool = false) {
        let output: KeypadOutput

        switch newItem {
        case true:
            // Update keypad with quantity of new currentItem
            //keypad.updateNumber(currentItem.quantity as Double?)
            keypad.updateNumber(currentItem.quantity?.doubleValue)
            output = keypad.output()
        case false:
            // Update model with output of keyapd
            output = keypad.output()

            if let keypadResult = output.total {
                currentItem.quantity = keypadResult as NSNumber?
            } else {
                currentItem.quantity = nil
            }
            managedObjectContext?.performSaveOrRollback()
        }

        updateDisplay(item: currentItem, keypadOutput: output)
    }

    // func updateDisplay(item: InventoryLocationItem, history: String, total: Double?, display: String) {}
    func updateDisplay(item: InventoryLocationItem, keypadOutput: KeypadOutput) {

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
