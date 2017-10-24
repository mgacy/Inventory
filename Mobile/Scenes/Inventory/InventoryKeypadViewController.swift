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
        viewModel.pushDigit(value: number)
    }

    @IBAction func clearTapped(_ sender: AnyObject) {
        viewModel.popItem()
    }

    @IBAction func decimalTapped(_ sender: AnyObject) {
        viewModel.pushDecimal()
    }

    // MARK: - Uncertain

    @IBAction func addTapped(_ sender: AnyObject) {
        viewModel.pushOperator()
    }

    @IBAction func decrementTapped(_ sender: AnyObject) {
        //log.verbose("Tapped '-1'")
    }

    @IBAction func incrementTapped(_ sender: AnyObject) {
        viewModel.pushOperator()
        viewModel.pushDigit(value: 1)
        viewModel.pushOperator()
    }

    // MARK: - Item Navigation

    @IBAction func nextItemTapped(_ sender: AnyObject) {
        switch viewModel.nextItem() {
        case true:
            return
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

    @IBAction func previousItemTapped(_ sender: AnyObject) {
        switch viewModel.previousItem() {
        case true:
            return
        case false:
            navigationController!.popViewController(animated: true)
        }
    }

}
