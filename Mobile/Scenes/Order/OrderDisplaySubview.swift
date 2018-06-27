//
//  OrderDisplaySubview.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/28/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

class OrderDisplaySubview: UIView {
    var viewModel: OrderKeypadViewModelType!
    //weak var viewController: OrderKeypadViewController?

    // Rx

    // MARK: - Appearance

    // Labels
    var activeLabelColor: UIColor = .black
    var inactiveLabelColor: UIColor = .lightGray

    // Label
    let labelColor: UIColor = .lightGray
    let labelFont: UIFont = UIFont.preferredFont(forTextStyle: .caption2)
    // Quantity
    let labelTextColor: UIColor = .black
    let labelTextFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    // Main
    let mainColor: UIColor = .black
    let mainFont: UIFont = UIFont.systemFont(ofSize: 60.0, weight: .regular)

    // MARK: - Interface

    // Par

    lazy var parLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelFont
        label.textColor = labelColor
        label.text = "Par"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var parTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelTextFont
        label.textColor = labelTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

//    private lazy var parStackView: UIStackView = {
//        let view = UIStackView(arrangedSubviews: [parLabel, parTextLabel])
//        view.axis = .vertical
//        view.alignment = .fill
//        view.distribution = .fillProportionally
//        view.spacing = 1
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()

    // On Hand

    lazy var onHandLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelFont
        label.textColor = labelColor
        label.text = "On Hand"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var onHandTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelTextFont
        label.textColor = labelTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

//    private lazy var onHandStackView: UIStackView = {
//        let view = UIStackView(arrangedSubviews: [onHandLabel, onHandTextLabel])
//        view.axis = .vertical
//        view.alignment = .fill
//        view.distribution = .fillProportionally
//        view.spacing = 1
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()

    // Min Order

    lazy var minOrderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelFont
        label.textColor = labelColor
        label.text = "Suggested"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var minOrderTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = labelTextFont
        label.textColor = labelTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

//    private lazy var minOrderStackView: UIStackView = {
//        let view = UIStackView(arrangedSubviews: [minOrderLabel, minOrderTextLabel])
//        view.axis = .vertical
//        view.alignment = .fill
//        view.distribution = .fillProportionally
//        view.spacing = 1
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()

    private lazy var infoStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [parLabel, parTextLabel, onHandLabel, onHandTextLabel, minOrderLabel,
                                                  minOrderTextLabel])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // B

    lazy var orderTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = mainFont
        label.textColor = mainColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var unitTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = mainFont
        label.textColor = mainColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var orderStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [orderTextLabel, unitTextLabel])
        view.axis = .horizontal
        view.alignment = .top
        view.distribution = .fill
        view.spacing = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var quantityStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [orderStackView])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // C

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [infoStackView, quantityStackView])
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fill
        view.spacing = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

//    private lazy var stackView: UIStackView = {
//        let view = UIStackView(arrangedSubviews: [_stackView])
//        view.axis = .vertical
//        view.alignment = .top
//        view.distribution = .fillProportionally
//        view.spacing = 0
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()

    // MARK: - Lifecycle

    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 600, height: 100))
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: - B

    //override func layoutIfNeeded() {}

    //override func layoutSubviews() {}

    // MARK: - My View Methods

    private func setupView() {
        //backgroundColor = inactiveBackgroundColor
        initSubViews()
        //configureGestureRecognizers()
        //colorSubViews()
        setupConstraints()
    }

    private func initSubViews() {
        addSubview(stackView)
    }

    //private func configureGestureRecognizers() {}

    private func setupConstraints() {
        let constraints = [
            // Quantity & Unit
            orderTextLabel.widthAnchor.constraint(equalTo: unitTextLabel.widthAnchor, multiplier: 2.0),
            // QuantityStack & InfoStack
            quantityStackView.widthAnchor.constraint(equalTo: infoStackView.widthAnchor, multiplier: 2.0),
            // Stack
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func colorSubViews() {
        // Info Stack
        parLabel.backgroundColor = .cyan
        parTextLabel.backgroundColor = .magenta
        onHandLabel.backgroundColor = .cyan
        onHandTextLabel.backgroundColor = .magenta
        minOrderLabel.backgroundColor = .cyan
        minOrderTextLabel.backgroundColor = .magenta
        // B
        orderTextLabel.backgroundColor = .brown
        unitTextLabel.backgroundColor = .orange
    }

    // MARK: - B

    func bind(to viewModel: OrderKeypadViewModelType) {
        self.viewModel = viewModel
        parTextLabel.text = viewModel.par
        onHandTextLabel.text = viewModel.onHand
        minOrderTextLabel.text = viewModel.suggestedOrder

        orderTextLabel.text = viewModel.orderQuantity
        unitTextLabel.text = viewModel.orderUnit
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

    // MARK: - Actions
}
