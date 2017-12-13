//
//  OrderKeypadViewController.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/30/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class OrderKeypadViewController: UIViewController {

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
        order.text = viewModel.orderQuantity
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        viewModel.popItem()
        order.text = viewModel.orderQuantity
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        viewModel.pushDecimal()
        order.text = viewModel.orderQuantity
    }

    // MARK: Units

    @IBAction func packTapped(_ sender: AnyObject) {
        guard viewModel.switchUnit(.packUnit) == true else {
            return
        }
        updateDisplay()
    }

    /// TODO: rename `individualTapped`?
    @IBAction func unitTapped(_ sender: AnyObject) {
        guard viewModel.switchUnit(.singleUnit) == true else {
            return
        }
        updateDisplay()
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

    // MARK: - Display

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
        updateKeypad()
    }

    /// TODO: rename `updateUnitButtons`?
    func updateKeypad() {
        caseButton.setTitle(viewModel.packUnitLabel, for: .normal)
        caseButton.isEnabled = viewModel.singleUnitIsEnabled

        bottleButton.setTitle(viewModel.singleUnitLabel, for: .normal)
        bottleButton.isEnabled = viewModel.packUnitIsEnabled

        guard let currentUnit = viewModel.currentUnit else {
            caseButton.backgroundColor = ColorPalette.secondary
            bottleButton.backgroundColor = ColorPalette.secondary
            return
        }

        switch currentUnit {
        case .singleUnit:
            caseButton.backgroundColor = ColorPalette.secondary
            bottleButton.backgroundColor = ColorPalette.navy
        case .packUnit:
            caseButton.backgroundColor = ColorPalette.navy
            bottleButton.backgroundColor = ColorPalette.secondary
        case .invalidUnit:
            caseButton.backgroundColor = ColorPalette.secondary
            bottleButton.backgroundColor = ColorPalette.secondary
        }
    }

}
