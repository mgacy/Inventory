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

    var viewModel: InvoiceKeypadViewModel!

    /*
    var inactiveUnit: Unit? {
        guard let item = currentItem.item else {
            log.debug("\(#function) : unable to get item of \(currentItem)")
            return nil
        }
        // Simply return currentItem.unit instead of nil?
        guard let pack = item.purchaseUnit else {
            log.debug("\(#function) : unable to get purchaseUnit of \(item)")
            return nil
        }
        guard let unit = item.purchaseSubUnit else {
            log.debug("\(#function) : unable to get purchaseSubUnit of \(item)")
            return nil
        }

        if currentItem.unit == unit {
            return pack
        } else if currentItem.unit == pack {
            return unit
        } else {
            log.warning("Unable to get inactiveUnit"); return nil
        }
    }
    */

    // MARK: - Display Outlets
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemQuantity: UILabel!
    @IBOutlet weak var itemCost: UILabel!
    @IBOutlet weak var itemStatus: UILabel!
    @IBOutlet weak var displayQuantity: UILabel!

    // MARK: - Keypad Outlets
    @IBOutlet weak var softButton: OperationKeypadButton!

    // MARK: - Lifecycle

    //override func viewDidLoad() {}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplay()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Keypad

    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        guard let number = Int(digit!) else { return }
        //if viewModel.currentMode == .status { return }
        viewModel.pushDigit(value: number)
        updateDisplay()
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        viewModel.popItem()
        updateDisplay()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        viewModel.pushDecimal()
        updateDisplay()
    }

    // MARK: Units
    /*
    @IBAction func softButtonTapped(_ sender: AnyObject) {
        switch currentMode {
        // Toggle currentItem.unit
        case .quantity:
            let currentUnit = currentItem.unit
            guard let newUnit = inactiveUnit else {
                log.error("\(#function) FAILED : unable to get inactiveUnit"); return
            }

            currentItem.unit = newUnit
            softButton.setTitle(currentUnit?.abbreviation, for: .normal)
            update()
        // ?
        case .cost:
            log.verbose("currentMode: \(currentMode)")
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

    */
    // MARK: Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        switch viewModel.nextItem() {
        case true:
            updateDisplay()
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        switch viewModel.previousItem() {
        case true:
            updateDisplay()
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: Mode

    @IBAction func modeTapped(_ sender: AnyObject) {
        switch viewModel.currentMode {
        case .cost:
            // -> status
            viewModel.switchMode(.status)
            updateDisplay()
        case .quantity:
            // -> cost
            viewModel.switchMode(.cost)
            updateDisplay()
        case .status:
            // -> quantity
            viewModel.switchMode(.quantity)
            updateDisplay()
        }
    }

    // MARK: - C

    func updateDisplay() {
        itemName.text = viewModel.itemName
        itemQuantity.text = viewModel.itemQuantity
        itemCost.text = viewModel.itemCost
        itemStatus.text = viewModel.itemStatus
        displayQuantity.text = viewModel.displayQuantity

        updateDisplayForCurrentMode()
    }

    func updateDisplayForCurrentMode() {
        switch viewModel.currentMode {
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
            /*
             // Should inactiveUnit simply return currentItem.unit instead of nil?
             if let altUnit = inactiveUnit {
             softButton.setTitle(altUnit.abbreviation, for: .normal)
             softButton.isEnabled = true
             } else {
             softButton.setTitle(currentItem.unit?.abbreviation, for: .normal)
             softButton.isEnabled = false
             }
             */
        case .status:
            itemCost.textColor = UIColor.lightGray
            itemQuantity.textColor = UIColor.lightGray
            itemStatus.textColor = UIColor.black
            softButton.setTitle("", for: .normal)
            softButton.isEnabled = true
        }
    }

}
