//
//  InventoryKeypadDisplayView.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/5/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class InventoryKeypadDisplayView: UIView {

    var dismissalEvents: Observable<DismissalEvent> {
        return itemDisplayView.dismissalEvents
    }

    // MARK: - Interface

    lazy var itemDisplayView: DisplayItemView = {
        let view = DisplayItemView()
        view.setContentHuggingPriority(UILayoutPriority(900.0), for: .vertical)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var inventoryDisplayView: InventoryDisplaySubview = {
        let view = InventoryDisplaySubview()
        view.setContentHuggingPriority(UILayoutPriority(600.0), for: .vertical)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [itemDisplayView, inventoryDisplayView])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        //view.distribution = .fillEqually
        //view.distribution = .fillProportionally
        //view.distribution = .equalSpacing
        //view.distribution = .equalCentering
        //view.spacing = 1.0
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

    // MARK: - My View Methods

    private func configure() {
        //backgroundColor = .white
        addSubview(stackView)
        setupConstraints()
    }

    private func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
            stackView.setCustomSpacing(24.0, after: itemDisplayView)
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: guide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
            //stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0)
            //stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
/*
// MARK: - Rx

extension Reactive where Base: InventoryKeypadDisplayView {

    var itemValueColor: Binder<UIColor> {
        return Binder(self.base) { (view, color) -> Void in
            view.inventoryDisplayView.itemValueLabel.textColor = color
        }
    }

    var itemValue: Binder<String?> {
        return Binder(self.base) { (view, string) -> Void in
            view.inventoryDisplayView.itemValueLabel.text = string
        }
    }

    var itemUnit: Binder<String?> {
        return Binder(self.base) { (view, string) -> Void in
            view.inventoryDisplayView.itemUnitLabel.text = string
        }
    }

    var itemHistory: Binder<String?> {
        return Binder(self.base) { (view, string) -> Void in
            view.inventoryDisplayView.itemHistoryLabel.text = string
        }
    }

}
*/
// MARK: - SubView

class InventoryDisplaySubview: UIView {

    // MARK: - Appearance

    // Labels
    //var activeLabelColor: UIColor = .black
    //var inactiveLabelColor: UIColor = .lightGray

    // Main
    let mainTextColor: UIColor = .black
    let mainFont: UIFont = UIFont.systemFont(ofSize: 60.0, weight: .regular)

    // History
    let historyTextColor: UIColor = .lightGray
    let historyFont: UIFont = UIFont.preferredFont(forTextStyle: .caption2)

    // MARK: - Interface

    lazy var itemValueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = mainFont
        label.textColor = mainTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var itemUnitLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = mainFont
        label.textColor = mainTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var quantityStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [itemValueLabel, itemUnitLabel])
        view.axis = .horizontal
        view.alignment = .top
        view.distribution = .fill
        view.spacing = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var itemHistoryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = historyFont
        label.textColor = historyTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [quantityStackView, itemHistoryLabel])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillProportionally
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 600, height: 100))
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: - My View Methods

    private func setupView() {
        addSubview(stackView)
        setupConstraints()
    }

    private func setupConstraints() {
        let constraints = [
            // Quantity & Unit
            itemUnitLabel.widthAnchor.constraint(equalToConstant: 100.0),
            // Stack
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
