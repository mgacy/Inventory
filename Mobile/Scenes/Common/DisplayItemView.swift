//
//  DisplayItemView.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/17/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

// MARK: - Protocol

public protocol DisplayItemViewModelType {
    var itemName: String { get }
    var itemPack: String { get }
}

// MARK: - View

class DisplayItemView: UIView {

    // MARK: - Properties

    var dismissalEvents: ControlEvent<Void> {
        return dismissChevron.rx.tap
    }

    // Appearance

    let nameTextColor: UIColor = .black
    let packTextColor: UIColor = .gray
    let nameFont: UIFont = UIFont.systemFont(ofSize: 34.0, weight: .semibold)
    let packFont: UIFont = UIFont.preferredFont(forTextStyle: .caption1)
    //let packFont: UIFont = UIFont.systemFont(ofSize: 12.0)

    // Subviews

    lazy var dismissChevron: ChevronButton = {
        let button = ChevronButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var itemName: UILabel = {
        let label = UILabel()
        label.font = nameFont
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = nameTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var itemPack: UILabel = {
        let label = UILabel()
        label.font = packFont
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = packTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [itemName, itemPack])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    private func configure() {
        backgroundColor = .white

        /// TESTING:
        let useStackView = false

        switch useStackView {
        case true:
            addSubview(stackView)
            setupConstraints2()
        case false:
            addSubview(dismissChevron)
            addSubview(stackView)
            setupConstraints3()
            //addSubview(itemName)
            //addSubview(itemPack)
            //setupConstraints()
        }
    }

    // MARK: - View Methods

    func colorSubViews() {
        dismissChevron.backgroundColor = .yellow
        itemName.backgroundColor = .cyan
        itemPack.backgroundColor = .magenta
    }

    func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            // DismissChevron
            dismissChevron.centerXAnchor.constraint(equalTo: centerXAnchor),
            dismissChevron.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10.0),
            dismissChevron.heightAnchor.constraint(equalToConstant: 15.0),
            dismissChevron.widthAnchor.constraint(equalToConstant: 38.0),
            // Name
            itemName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            itemName.topAnchor.constraint(equalTo: dismissChevron.bottomAnchor, constant: 20.0),
            itemName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            // Pack
            itemPack.leadingAnchor.constraint(equalTo: itemName.leadingAnchor),
            itemPack.topAnchor.constraint(equalTo: itemName.bottomAnchor),
            itemPack.trailingAnchor.constraint(equalTo: itemName.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// For use with UIStackView
    func setupConstraints2() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            dismissChevron.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: guide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupConstraints3() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            // DismissChevron
            dismissChevron.centerXAnchor.constraint(equalTo: centerXAnchor),
            dismissChevron.topAnchor.constraint(equalTo: guide.topAnchor, constant: 0.0),
            dismissChevron.heightAnchor.constraint(equalToConstant: 10.0),
            dismissChevron.widthAnchor.constraint(equalToConstant: 38.0),
            // StackView
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12.0),
            stackView.topAnchor.constraint(equalTo: dismissChevron.bottomAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 16.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - A

    func bind(to viewModel: DisplayItemViewModelType) {
        itemName.text = viewModel.itemName
        itemPack.text = viewModel.itemPack
    }

}
