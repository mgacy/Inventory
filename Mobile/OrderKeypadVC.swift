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

    // MARK: - Properties

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
            log.error("Error with request: \(error)")
        }
        return [OrderItem]()
    }

    var currentItem: OrderItem {
        //log.verbose("currentItem: \(items[currentIndex])")
        return items[currentIndex]
    }

    typealias KeypadOutput = (total: Double?, display: String)
    let keypad = Keypad()

    // CoreData
    var managedObjectContext: NSManagedObjectContext?

    var numberFormatter: NumberFormatter?

    // MARK: - Display Outlets

    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var par: UILabel!
    @IBOutlet weak var onHand: UILabel!
    @IBOutlet weak var minOrder: UILabel!
    @IBOutlet weak var caseSize: UILabel!
    @IBOutlet weak var order: UILabel!
    @IBOutlet weak var orderUnit: UILabel!

    // MARK: - Keypad Outlets

    @IBOutlet weak var caseButton: OperationKeypadButton!
    @IBOutlet weak var bottleButton: OperationKeypadButton!

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

    // MARK: - Keypad

    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        //log.verbose("Tapped '\(digit)'")
        guard let number = Int(digit!) else { return }
        keypad.pushDigit(value: number)

        update()
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        //log.verbose("Tapped 'clear'")
        keypad.popItem()

        update()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        //log.verbose("Tapped '.'")
        keypad.pushDecimal()

        update()
    }

    // MARK: Units

    @IBAction func packTapped(_ sender: AnyObject) {
        guard let item = currentItem.item else {
            log.debug("\(#function) : unable to get item of \(currentItem)")
            return
        }
        guard let purchaseUnit = item.purchaseUnit else {
            log.debug("\(#function) : unable to get purchaseUnit of \(item)")
            return
        }

        currentItem.orderUnit = purchaseUnit

        // Update display, keypad buttons
        update()
    }

    /// TODO: rename `individualTapped`?
    @IBAction func unitTapped(_ sender: AnyObject) {
        guard let item = currentItem.item else {
            log.debug("\(#function) : unable to get item of \(currentItem)")
            return
        }
        guard let purchaseSubUnit = item.purchaseSubUnit else {
            log.debug("\(#function) : unable to get purchaseSubUnit of \(item)")
            return
        }

        currentItem.orderUnit = purchaseSubUnit

        // Update display, keypad buttons
        update()
    }

    // MARK: Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            update(newItem: true)
        } else {
            /// TODO: cleanup?

            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        if currentIndex > 0 {
            currentIndex -= 1
            update(newItem: true)
        } else {
            /// TODO: cleanup?

            // Pop view
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: - C

    func update(newItem: Bool = false) {

        let output: KeypadOutput

        switch newItem {
        case true:
            // Update keypad with quantity of new currentItem
            keypad.updateNumber(currentItem.quantity as Double?)
            output = keypad.outputB()

        case false:
            // Update model with output of keypad
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
                log.error("Unresolved error \(nserror), \(nserror.userInfo)")
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }

        updateKeypadButtons(item: currentItem)
        updateDisplay(item: currentItem, keypadOutput: output)

        //log.verbose("currentItem: \(currentItem)")
    }

    func updateDisplay(item: OrderItem, keypadOutput: KeypadOutput) {
        guard let item = currentItem.item else {
            itemName.text = "Error (1)"; return
        }
        guard let name = item.name else {
            itemName.text = "Error (2)" ; return
        }
        itemName.text = name

        caseSize.text = item.packDisplay
        par.text = formDisplayLine(
            quantity: currentItem.par, abbreviation: currentItem.parUnit?.abbreviation ?? " ")
        onHand.text = formDisplayLine(
            quantity: currentItem.onHand, abbreviation: currentItem.item?.inventoryUnit?.abbreviation ?? " ")
        minOrder.text = formDisplayLine(
            quantity: currentItem.minOrder, abbreviation: currentItem.minOrderUnit?.abbreviation ?? " ")

        order.text = keypadOutput.display
        orderUnit.text = currentItem.orderUnit?.abbreviation

        switch keypadOutput.total {
        case nil:
            order.textColor = UIColor.lightGray
            orderUnit.textColor = UIColor.lightGray
        case 0.0?:
            order.textColor = UIColor.lightGray
            orderUnit.textColor = UIColor.lightGray
        default:
            order.textColor = UIColor.black
            orderUnit.textColor = UIColor.black
        }

    }

    /// TODO: rename `updateUnitButtons`?
    func updateKeypadButtons(item: OrderItem) {
        guard let orderUnit = currentItem.orderUnit else {
            log.warning("\(#function) FAILED : 1"); return
        }
        guard let item = currentItem.item else {
            log.warning("\(#function) FAILED : 2"); return
        }

        //log.verbose("currentItem: \(currentItem)")
        //log.verbose("currentItem.item: \(item)")

        /// TODO: some of this should only be done when we change currentItem
        if orderUnit == item.purchaseUnit {
            caseButton.backgroundColor = ColorPalette.navyColor
            caseButton.isEnabled = true

            bottleButton.backgroundColor = ColorPalette.secondaryColor
            if item.purchaseSubUnit != nil {
                bottleButton.isEnabled = true
            } else {
                bottleButton.isEnabled = false
            }

        } else if orderUnit == item.purchaseSubUnit {
            bottleButton.backgroundColor = ColorPalette.navyColor
            bottleButton.isEnabled = true

            caseButton.backgroundColor = ColorPalette.secondaryColor
            if item.purchaseUnit != nil {
                caseButton.isEnabled = true
            } else {
                caseButton.isEnabled = false
            }

        } else {
            log.warning("\(#function) FAILED : 3")
            caseButton.isEnabled = false
            bottleButton.isEnabled = false
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
