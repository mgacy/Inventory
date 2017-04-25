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

    // MARK: - Properties

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

    var inactiveUnit: Unit? {
        guard let item = currentItem.item else { print("A1"); return nil  }
        // Simply return currentItem.unit instead of nil?
        guard let pack = item.purchaseUnit else { print("A2"); return nil }
        guard let unit = item.purchaseSubUnit else { print("A3"); return nil }

        if currentItem.unit == unit {
            return pack
        } else if currentItem.unit == pack {
            return unit
        } else {
            print("Unable to get inactiveUnit"); return nil
        }
    }

    typealias keypadOutput = (total: Double?, display: String)
    let keypad = Keypad()

    /// TODO: include relevant methods within this?
    enum KeypadState {
        case quantity
        case cost
        case status
    }

    /// TODO: should default mode be cost, since that is most likely to vary?
    var currentMode: KeypadState = .quantity

    // CoreData
    var managedObjectContext: NSManagedObjectContext?

    var numberFormatter: NumberFormatter?
    var currencyFormatter: NumberFormatter?

    // MARK: - Display Outlets
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemQuantity: UILabel!
    @IBOutlet weak var itemCost: UILabel!
    @IBOutlet weak var itemStatus: UILabel!
    @IBOutlet weak var displayQuantity: UILabel!

    // MARK: - Keypad Outlets
    @IBOutlet weak var softButton: OperationKeypadButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup numberFormatter
        numberFormatter = NumberFormatter()
        guard let numberFormatter = numberFormatter else { return }
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits = 2

        // Setup currencyFormatter
        currencyFormatter = NumberFormatter()
        guard let currencyFormatter = currencyFormatter else { return }
        currencyFormatter.numberStyle = .currency

        // Reset mode to quantity; this also calls update(newItem: true)
        switchMode(.quantity)
        //update(newItem: true)
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
        if currentMode == .status { return }

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

    // MARK: Units

    @IBAction func softButtonTapped( _sender: AnyObject) {
        switch currentMode {
        // Toggle currentItem.unit
        case .quantity:
            let currentUnit = currentItem.unit
            guard let newUnit = inactiveUnit else {
                print("\(#function) FAILED : unable to get inactiveUnit"); return
            }

            currentItem.unit = newUnit
            softButton.setTitle(currentUnit?.abbreviation, for: .normal)
            update()
        // ?
        case .cost:
            print("z2")
        // ?
        case .status:
            if var status = InvoiceItemStatus(rawValue: currentItem.status) {
                status.next()
                currentItem.status = status.rawValue
                //status.next()
                //softButton.setTitle(status.shortDescription, for: .normal)

            }
            softButton.setTitle("s", for: .normal)
            update()
        }
    }

    @IBAction func packTapped(_ sender: AnyObject) {
        guard let item = currentItem.item else { print("A1"); return  }
        guard let purchaseUnit = item.purchaseUnit else { print("B1"); return }

        currentItem.unit = purchaseUnit
        update()
    }

    /// TODO: rename `individualTapped`?
    @IBAction func unitTapped(_ sender: AnyObject) {
        guard let item = currentItem.item else { print("A2"); return  }
        print("Item: \(item)")
        guard let purchaseSubUnit = item.purchaseSubUnit else { print("B2"); return }

        currentItem.unit = purchaseSubUnit
        update()
    }

    // MARK: Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1

            // Reset mode to quantity; this also calls update(newItem: true)
            switchMode(.quantity)
            //update(newItem: true)
        } else {
            /// TODO: cleanup?

            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1

            // Reset mode to quantity; this also calls update(newItem: true)
            switchMode(.quantity)
            //update(newItem: true)
        } else {
            /// TODO: cleanup?

            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: Mode

    @IBAction func modeTapped(_ sender: AnyObject) {
        switch currentMode {
        case .cost:
            // -> status
            switchMode(.status)
        case .quantity:
            // -> cost
            switchMode(.cost)
        case .status:
            // -> quantity
            switchMode(.quantity)
        }
    }

    // MARK: -

    func switchMode(_ newMode: KeypadState) {
        currentMode = newMode

        switch newMode {
        case .cost:
            itemCost.textColor = UIColor.black
            itemQuantity.textColor = UIColor.lightGray
            itemStatus.textColor = UIColor.lightGray
            softButton.setTitle("", for: .normal)
            softButton.isEnabled = false
        case .quantity:
            itemCost.textColor = UIColor.lightGray
            itemQuantity.textColor = UIColor.black
            itemStatus.textColor = UIColor.lightGray

            // Should inactiveUnit simply return currentItem.unit instead of nil?
            if let altUnit = inactiveUnit {
                softButton.setTitle(altUnit.abbreviation, for: .normal)
                softButton.isEnabled = true
            } else {
                softButton.setTitle(currentItem.unit?.abbreviation, for: .normal)
                softButton.isEnabled = false
            }

        case .status:
            itemCost.textColor = UIColor.lightGray
            itemQuantity.textColor = UIColor.lightGray
            itemStatus.textColor = UIColor.black
            softButton.setTitle("", for: .normal)
            softButton.isEnabled = true
        }

        /// TODO: what is the best way to handle this?
        update(newItem: true)
        /// TODO: is this something that should be always be done in Keypad?
        keypad.isEditingNumber = false
    }

    // MARK: - C

    func update(newItem: Bool = false) {

        let output: keypadOutput

        switch newItem {
        case true:
            // Update keypad with quantity of new currentItem
            switch currentMode {
            case .cost:
                keypad.updateNumber(currentItem.cost as Double?)
                output = keypad.outputB()
            case .quantity:
                keypad.updateNumber(currentItem.quantity as Double?)
                output = keypad.outputB()

            case .status:
                print("update - status")
                // TESTING
                output = (total: 1.0, display: "Test")
            }

        case false:
            // Update model with output of keyapd
            output = keypad.outputB()

            switch currentMode {
            case .cost:
                if let keypadResult = output.total {
                    currentItem.cost = keypadResult
                } else {
                    /// TODO: how to handle this?
                    //currentItem.cost = nil
                    print("\nPROBLEM - Unable to set InventoryItem.cost to nil")
                }

            case .quantity:
                if let keypadResult = output.total {
                    currentItem.quantity = keypadResult
                } else {
                    /// TODO: how to handle this?
                    //currentItem.quantity = nil
                    print("\nPROBLEM - Unable to set InventoryItem.quantity to nil")
                }

            case .status:
                print("update - status")
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

    // MARK: - B

    func updateDisplay(item: InvoiceItem, keypadOutput: keypadOutput) {
        guard let item = currentItem.item else {
            itemName.text = "Error (1)"; return
        }
        guard let name = item.name else {
            itemName.text = "Error (2)" ; return
        }
        itemName.text = name

        // Get strings for display
        let quantityString = formDisplayLine(
            quantity: currentItem.quantity,
            abbreviation: currentItem.unit?.abbreviation ?? " ")
        let costString = currencyFormatter?.string(from: NSNumber(value: currentItem.cost))

        let statusString: String
        if let _statusString = InvoiceItemStatus(rawValue: currentItem.status)?.description {
            statusString = _statusString
        } else {
            statusString = ""
        }

        /*
         itemQuantity.text = formDisplayLine(
         quantity: currentItem.quantity,
         abbreviation: currentItem.unit?.abbreviation ?? " ")
         itemCost.text = currencyFormatter?.string(from: NSNumber(value: currentItem.cost))
         //itemStatus.text = currentItem.status
         */

        switch currentMode {
        case .cost:
            itemQuantity.text = quantityString
            //itemCost.text = ""
            itemCost.text = costString
            itemStatus.text = statusString
            displayQuantity.text = costString
        case .quantity:
            //itemQuantity.text = ""
            itemQuantity.text = quantityString
            itemCost.text = costString
            itemStatus.text = statusString
            displayQuantity.text = quantityString
        case .status:
            itemQuantity.text = quantityString
            itemCost.text = costString
            //itemStatus.text = ""
            itemStatus.text = statusString
            displayQuantity.text = statusString
        }
    }

    private func formDisplayLine(quantity: Double?, abbreviation: String) -> String {
        guard let numberFormatter = numberFormatter else { return "ERROR 3" }
        guard let quantity = quantity else { return "ERROR 4" }

        // Quantity
        if let quantityString = numberFormatter.string(from: NSNumber(value: quantity)) {
            return "\(quantityString) \(abbreviation)"
        }
        return ""
    }

}
