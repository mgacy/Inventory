//
//  OrderKeypadDisplayView.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/28/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class OrderKeypadDisplayView: UIView {

    var dismissalEvents: ControlEvent<Void> {
        return itemDisplayView.dismissalEvents
    }

    // MARK: - Interface

    lazy var itemDisplayView: DisplayItemView = {
        let view = DisplayItemView()
        view.setContentHuggingPriority(UILayoutPriority(900.0), for: .vertical)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var orderDisplayView: OrderDisplaySubview = {
        let view = OrderDisplaySubview()
        view.setContentHuggingPriority(UILayoutPriority(600.0), for: .vertical)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [itemDisplayView, orderDisplayView])
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
        orderDisplayView.backgroundColor = UIColor.yellow
        orderDisplayView.colorSubViews()
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

    // MARK: - B

    func bind(to viewModel: OrderKeypadViewModelType & DisplayItemViewModelType) {
        itemDisplayView.bind(to: viewModel)
        orderDisplayView.bind(to: viewModel)
    }

}
