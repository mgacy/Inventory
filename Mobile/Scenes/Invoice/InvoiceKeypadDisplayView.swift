//
//  InvoiceKeypadDisplayView.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/17/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class InvoiceKeypadDisplayView: UIView {

    var dismissalEvents: ControlEvent<Void> {
        return itemDisplayView.dismissalEvents
    }

    // MARK: - Interface

    lazy var itemDisplayView: DisplayItemView = {
        let view = DisplayItemView()
        //view.setContentHuggingPriority(UILayoutPriority(900.0), for: .vertical)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var invoiceDisplayView: InvoiceDisplaySubview = {
        let view = InvoiceDisplaySubview()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [itemDisplayView, invoiceDisplayView])
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

    private func configure() {
        //backgroundColor = .white
        addSubview(stackView)
        setupConstraints()
        //colorSubViews()
    }

    //override func layoutSubviews() {}

    // MARK: - A

    func colorSubViews() {
        itemDisplayView.backgroundColor = UIColor.red
        itemDisplayView.colorSubViews()
        invoiceDisplayView.backgroundColor = UIColor.yellow
        invoiceDisplayView.colorSubViews()
    }

    private func setupConstraints() {
        let guide: UILayoutGuide
        if #available(iOS 11, *) {
            guide = safeAreaLayoutGuide
            stackView.setCustomSpacing(16.0, after: itemDisplayView)
        } else {
            guide = layoutMarginsGuide
        }
        let constraints = [
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: guide.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - B

    func bind(to viewModel: InvoiceKeypadViewModel) {
        itemDisplayView.bind(to: viewModel)
        invoiceDisplayView.bind(to: viewModel)
    }

}
