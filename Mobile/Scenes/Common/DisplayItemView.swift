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

    var dismissalEvents: Observable<DismissalEvent> {
        return dismissChevron.rx.tap.map { _ in .shouldDismiss }
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
        addSubview(dismissChevron)
        addSubview(stackView)
        setupConstraints()
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
            dismissChevron.topAnchor.constraint(equalTo: guide.topAnchor, constant: 0.0),
            dismissChevron.heightAnchor.constraint(equalToConstant: 10.0),
            dismissChevron.widthAnchor.constraint(equalToConstant: 38.0),
            // StackView
            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12.0),
            stackView.topAnchor.constraint(equalTo: dismissChevron.bottomAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12.0),
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

// MARK: - Rx

public protocol ReactiveDisplayItemViewModelType {
    var itemName: Observable<String> { get }
    var itemPack: Observable<String> { get }
}

extension Reactive where Base: DisplayItemView {

    var itemName: Binder<String?> {
        return Binder(self.base) { (view, string) -> Void in
            view.itemName.text = string
        }
    }

    var itemPack: Binder<String?> {
        return Binder(self.base) { (view, string) -> Void in
            view.itemPack.text = string
        }
    }

}
