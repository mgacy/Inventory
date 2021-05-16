//
//  KeypadView.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/17/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

// swiftlint:disable file_length

// MARK: - Protocol

protocol KeypadViewControllerType: class {
    func numberTapped(sender: UIButton)
    func clearTapped(sender: UIButton)
    func decimalTapped(_ sender: UIButton)
    func softButton1Tapped(sender: UIButton)
    func softButton2Tapped(sender: UIButton)
    func nextItemTapped(_ sender: UIButton)
    func previousItemTapped(_ sender: UIButton)
}

// MARK: - Commands

enum KeypadCommands {
    case number(Int)
    case clear
    case decimal
    case next
    case previous
    case soft1
    case soft2
}

// MARK: - View

// swiftlint:disable:next type_body_length
class KeypadView: UIView {

    // MARK: - Appearance

    let buttonFont: UIFont = UIFont.systemFont(ofSize: 22.0)
    let buttonDividerColor: UIColor = .white
    let buttonDividerWidth: CGFloat = 1.0

    // Number Buttons
    let numberColor: UIColor = .white
    let numberBackgroundColor: UIColor = ColorPalette.lightGray

    // Operation Buttons
    let operationTextColor: UIColor = .white
    let operationBackgroundColor: UIColor = ColorPalette.secondary

    weak var viewController: KeypadViewControllerType?
    //private var viewModel: InvoiceKeypadViewModel

    lazy var backingView: UIView = {
        let view = UIView()
        view.backgroundColor = buttonDividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Rx

    var buttonTaps: Observable<KeypadCommands> {
        return Observable.of(
            button0.rx.tap.map { _ in .number(0) },
            button1.rx.tap.map { _ in .number(1) },
            button2.rx.tap.map { _ in .number(2) },
            button3.rx.tap.map { _ in .number(3) },
            button4.rx.tap.map { _ in .number(4) },
            button5.rx.tap.map { _ in .number(5) },
            button6.rx.tap.map { _ in .number(6) },
            button7.rx.tap.map { _ in .number(7) },
            button8.rx.tap.map { _ in .number(8) },
            button9.rx.tap.map { _ in .number(9) },
            decimalButton.rx.tap.map { _ in .decimal },
            previousButton.rx.tap.map { _ in .previous },
            nextButton.rx.tap.map { _ in .next },
            deleteButton.rx.tap.map { _ in .clear },
            softButton1.rx.tap.map { _ in .soft1 },
            softButton2.rx.tap.map { _ in .soft2 }
        )
            .merge()
    }

    // MARK: - Buttons

    // MARK: Number Pad

    lazy var button0: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("0", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button1: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("1", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button2: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("2", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button3: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("3", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button4: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("4", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button5: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("5", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button6: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("6", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button7: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("7", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button8: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("8", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var button9: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle("9", for: .normal)
        button.addTarget(self, action: #selector(numberTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var decimalButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = numberBackgroundColor
        button.titleLabel?.font = buttonFont
        button.setTitle(".", for: .normal)
        button.addTarget(self, action: #selector(decimalTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: Navigation

    lazy var previousButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "prev"), for: .normal)
        button.backgroundColor = operationBackgroundColor
        button.addTarget(self, action: #selector(previousItemTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "next"), for: .normal)
        button.backgroundColor = operationBackgroundColor
        button.addTarget(self, action: #selector(nextItemTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        button.backgroundColor = operationBackgroundColor
        button.addTarget(self, action: #selector(clearTapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: Soft

    lazy var softButton1: UIButton = {
        let button = UIButton()
        button.backgroundColor = operationBackgroundColor
        button.titleLabel?.font = buttonFont
        button.addTarget(self, action: #selector(softButton1Tapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var softButton2: UIButton = {
        let button = UIButton()
        button.backgroundColor = operationBackgroundColor
        button.titleLabel?.font = buttonFont
        button.addTarget(self, action: #selector(softButton2Tapped(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - StackViews

    private lazy var columnStack1: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [button7, button4, button1, button0])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = buttonDividerWidth
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var columnStack2: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [button8, button5, button2, decimalButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = buttonDividerWidth
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var columnStack3: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [button9, button6, button3, previousButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = buttonDividerWidth
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var columnStack4: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [deleteButton, softButton1, softButton2, nextButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = buttonDividerWidth
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var rowStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [columnStack1, columnStack2, columnStack3, columnStack4])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = buttonDividerWidth
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 600, height: 200))
        self.configure()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }

    // MARK: - View Methods

    private func configure() {
        addSubview(backingView)
        addSubview(rowStack)
        setupConstraints()
    }

    private func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            // BackingView
            backingView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            backingView.topAnchor.constraint(equalTo: guide.topAnchor),
            backingView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            backingView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            // StackView
            rowStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            rowStack.topAnchor.constraint(equalTo: guide.topAnchor),
            rowStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -buttonDividerWidth),
            // Buttons (1)
            deleteButton.heightAnchor.constraint(equalTo: button9.heightAnchor),
            nextButton.heightAnchor.constraint(equalTo: previousButton.heightAnchor),
            // Buttons (2)
            softButton1.heightAnchor.constraint(equalTo: softButton2.heightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}

// MARK: - Button Methods

extension KeypadView {

    @objc func numberTapped(sender: UIButton) {
        //log.verbose("\(#function)")
        //guard let title = sender.currentTitle, let number = Int(title) else { return }
        viewController?.numberTapped(sender: sender)
    }

    @objc func clearTapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.clearTapped(sender: sender)
    }

    @objc func decimalTapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.decimalTapped(sender)
    }

    // MARK: Soft Buttons

    @objc func softButton1Tapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.softButton1Tapped(sender: sender)
    }

    @objc func softButton2Tapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.softButton2Tapped(sender: sender)
    }

    // MARK: Item Navigation

    @objc func nextItemTapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.nextItemTapped(sender)
    }

    @objc func previousItemTapped(sender: UIButton) {
        //log.verbose("\(#function)")
        viewController?.previousItemTapped(sender)
    }

}
