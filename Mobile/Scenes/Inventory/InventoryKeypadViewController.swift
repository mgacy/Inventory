//
//  InventoryKeypadViewController.swift
//  Playground
//
//  Created by Mathew Gacy on 10/10/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InventoryKeypadViewController: UIViewController {

    // MARK: Properties

    var viewModel: InventoryKeypadViewModel!
    let disposeBag = DisposeBag()

    /*
    var parentObject: LocationItemListParent = .none
    var currentIndex = 0

    var items: [InventoryLocationItem] {
        let request: NSFetchRequest<InventoryLocationItem> = InventoryLocationItem.fetchRequest()

        let positionSort = NSSortDescriptor(key: "position", ascending: true)
        let nameSort = NSSortDescriptor(key: "item.name", ascending: true)
        request.sortDescriptors = [positionSort, nameSort]

        guard let fetchPredicate = parentObject.fetchPredicate else {
            fatalError("\(#function) FAILED : LocationItemListParent not set")
        }
        request.predicate = fetchPredicate

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
     */

    // MARK: - Display Outlets
    @IBOutlet weak var itemValue: UILabel!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemHistory: UILabel!
    @IBOutlet weak var itemPack: UILabel!
    @IBOutlet weak var itemUnit: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        //update(newItem: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("\(#function)")
        // Dispose of any resources that can be recreated.
    }

    // MARK: - View Methods

    func setupBindings() {
        viewModel.itemName
            .asObservable()
            .map { $0 }
            .bind(to: itemName.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemValue
            .asObservable()
            .map { $0 }
            .bind(to: itemValue.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemHistory
            .asObservable()
            .map { $0 }
            .bind(to: itemHistory.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemPack
            .asObservable()
            .map { $0 }
            .bind(to: itemPack.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemUnit
            .asObservable()
            .map { $0 }
            .bind(to: itemUnit.rx.text)
            .disposed(by: disposeBag)

        viewModel.itemValueColor
            .asObservable()
            //.bind(to: itemValue.rx.)
            .subscribe(onNext: {[weak self] color in
                self?.itemValue.textColor = color
            })
            .disposed(by: disposeBag)

    }

    // MARK: - Keypad

    @IBAction func numberTapped(_ sender: AnyObject) {
        guard let digit = sender.currentTitle else { return }
        //log.verbose("Tapped '\(digit)'")
        guard let number = Int(digit!) else { return }
        /*
        keypad.pushDigit(value: number)

        // Update model and display with result of keypad
        update()
         */
        viewModel.pushDigit(value: number)
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        /*
        keypad.popItem()
        update()
         */
        viewModel.popItem()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        /*
        keypad.pushDecimal()
        update()
        */
        viewModel.pushDecimal()
    }

    // MARK: - Uncertain

    @IBAction func addTapped(_ sender: AnyObject) {
        /*
        keypad.pushOperator()
        update()
         */
        viewModel.pushOperator()
    }

    @IBAction func decrementTapped(_ sender: AnyObject) {
        //log.verbose("Tapped '-1'")
    }

    @IBAction func incrementTapped(_ sender: AnyObject) {
        /*
        keypad.pushOperator()
        keypad.pushDigit(value: 1)
        keypad.pushOperator()
        update()
         */
        viewModel.pushOperator()
        viewModel.pushDigit(value: 1)
        viewModel.pushOperator()
    }

    // MARK: - Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        /*
        if currentIndex < items.count - 1 {
            currentIndex += 1
            // Update keypad and display with new currentItem
            update(newItem: true)
        } else {
            /// TODO: cleanup?
            navigationController!.popViewController(animated: true)
        }
         */
        switch viewModel.nextItem() {
        case true:
            return
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        /*
        if currentIndex > 0 {
            currentIndex -= 1
            // Update keypad and display with new currentItem
            update(newItem: true)
        } else {
            /// TODO: cleanup?
            navigationController!.popViewController(animated: true)
        }
         */
        switch viewModel.previousItem() {
        case true:
            return
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

    // MARK: - View

    // MARK: - View
    /*
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
     */

}
