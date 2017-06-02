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

    var viewModel: OrderKeypadViewModel!

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
        viewModel.pushDigit(value: number)
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        viewModel.popItem()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        viewModel.pushDecimal()
    }

    // MARK: Units

    @IBAction func packTapped(_ sender: AnyObject) {
        /*
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
        */
    }

    /// TODO: rename `individualTapped`?
    @IBAction func unitTapped(_ sender: AnyObject) {
        /*
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
        */
    }

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

    // MARK: - C

    func updateDisplay() {
        itemName.text = viewModel.name

        caseSize.text = viewModel.pack
        par.text = viewModel.par
        onHand.text = viewModel.onHand
        minOrder.text = viewModel.suggestedOrder

        order.text = viewModel.orderQuantity
        orderUnit.text = viewModel.orderUnit
        /*
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
        */
    }

    func updateKeypad() {
        caseButton.setTitle(viewModel.packUnitLabel, for: .normal)
        caseButton.backgroundColor = ColorPalette.navyColor
        caseButton.isEnabled = true

        bottleButton.setTitle(viewModel.singleUnitLabel, for: .normal)
        bottleButton.backgroundColor = ColorPalette.secondaryColor
        bottleButton.isEnabled = true
    }

    /*

    /// TODO: rename `updateUnitButtons`?
    func updateKeypadButtons(item: OrderItem) {

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

    */
}
