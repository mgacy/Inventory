//
//  InvoiceDisplaySubview.swift
//  Mobile
//
//  Created by Mathew Gacy on 5/21/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

// swiftlint:disable file_length
// swiftlint:disable type_body_length

class InvoiceDisplaySubview: UIView {
    typealias KeypadMode = InvoiceKeypadViewModel.KeypadState

    var viewModel: InvoiceKeypadViewModel!
    weak var viewController: InvoiceKeypadViewController?

    // Rx
    //private let _modeTapped = PulishSubject<KeypadMode>()
    //var modeTapped: Observable<KeypadMode> {
    //    return _modeTapped.asObservable()
    //}

    // MARK: - Appearance

    var activeBackgroundColor: UIColor = .white
    var inactiveBackgroundColor: UIColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)

    // Labels
    var activeLabelColor: UIColor = .black
    var inactiveLabelColor: UIColor = .lightGray
    let labelFont: UIFont = UIFont.preferredFont(forTextStyle: .title1)

    // Divider
    let dividerColor: UIColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.35)
    let dividerWidth: CGFloat = 0.5

    // Animation
    private let animationDuration: TimeInterval = 0.30
    private let animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    private let animationOptions: UIViewAnimationOptions = .transitionCrossDissolve

    private var costTapGestureRecognizer: UITapGestureRecognizer!
    private var quantityTapGestureRecognizer: UITapGestureRecognizer!
    private var statusTapGestureRecognizer: UITapGestureRecognizer!

    //override func requiresConstraintBasedLayout() -> Bool { return true }

    // MARK: - Interface

    private lazy var topDivider: UIView = {
        let view = UIView()
        view.backgroundColor = dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Cost

    lazy var costTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = labelFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Quantity

    private lazy var costAndQuantityDivider: UIView = {
        let view = UIView()
        view.backgroundColor = dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var quantityTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = labelFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var quantityUnitView: UnitView = {
        let view = UnitView(currentUnit: .singleUnit)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var quantityStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [quantityTextLabel, quantityUnitView])
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Status

    private lazy var quantityAndStatusDivider: UIView = {
        let view = UIView()
        view.backgroundColor = dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var statusTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = labelFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var bottomDivider: UIView = {
        let view = UIView()
        view.backgroundColor = dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [costTextLabel, quantityStackView, statusTextLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // Highlight

    lazy var highlightView: InvoiceDisplayHighlightView = {
        let view = InvoiceDisplayHighlightView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = activeBackgroundColor
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
        backgroundColor = inactiveBackgroundColor
        initSubViews()
        configureGestureRecognizers()
        //colorSubViews()
        setupConstraints()
    }

    private func initSubViews() {
        addSubview(highlightView)
        addSubview(stackView)

        // Dividers
        addSubview(topDivider)
        addSubview(costAndQuantityDivider)
        addSubview(quantityAndStatusDivider)
        addSubview(bottomDivider)
    }

    private func configureGestureRecognizers() {
        // Taps on Quantity
        quantityTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(switchToQuantity))
        quantityStackView.addGestureRecognizer(quantityTapGestureRecognizer!)
        quantityStackView.isUserInteractionEnabled = true

        // Taps on Cost
        costTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(switchToCost))
        costTextLabel.addGestureRecognizer(costTapGestureRecognizer)
        costTextLabel.isUserInteractionEnabled = true

        // Taps on Status
        statusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(switchToStatus))
        statusTextLabel.addGestureRecognizer(statusTapGestureRecognizer)
        statusTextLabel.isUserInteractionEnabled = true
    }

    private func setupConstraints() {
        // Dividers
        let dividerConstraints = [
            // Top
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: dividerWidth),
            // Cost - Quantity
            costAndQuantityDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            costAndQuantityDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            costAndQuantityDivider.topAnchor.constraint(equalTo: quantityStackView.topAnchor),
            costAndQuantityDivider.heightAnchor.constraint(equalToConstant: dividerWidth),
            // Quantity - Status
            quantityAndStatusDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            quantityAndStatusDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            quantityAndStatusDivider.topAnchor.constraint(equalTo: statusTextLabel.topAnchor),
            quantityAndStatusDivider.heightAnchor.constraint(equalToConstant: dividerWidth),
            // Bottom
            bottomDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDivider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1.0),
            bottomDivider.heightAnchor.constraint(equalToConstant: dividerWidth)
        ]
        NSLayoutConstraint.activate(dividerConstraints)

        let constraints = [
            // UnitViews
            quantityUnitView.widthAnchor.constraint(equalToConstant: 28.0),
            quantityUnitView.heightAnchor.constraint(equalToConstant: 28.0),
            // Stack Views
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            // Highlight View
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            highlightView.topAnchor.constraintEqualToAnchor(anchor: costTextLabel.topAnchor, constant: 0.0,
                                                            identifier: "topAnchor"),
            highlightView.bottomAnchor.constraintEqualToAnchor(anchor: costTextLabel.bottomAnchor, constant: 0.0,
                                                               identifier: "bottomAnchor")
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func colorSubViews() {
        costTextLabel.backgroundColor = UIColor.cyan
        quantityTextLabel.backgroundColor = UIColor.magenta
        quantityUnitView.backgroundColor = UIColor.yellow
        statusTextLabel.backgroundColor = UIColor.brown
    }

    // MARK: - B

    func bind(to viewModel: InvoiceKeypadViewModel) {
        self.viewModel = viewModel
        quantityTextLabel.text = viewModel.itemQuantity
        quantityUnitView.updateUnit(viewModel.currentUnit ?? .invalidUnit)
        costTextLabel.text = viewModel.itemCost
        statusTextLabel.text = viewModel.itemStatus
    }

    // MARK: - Actions

    @objc private func switchToCost() {
        //viewModel.switchMode(.cost)
        viewController?.switchMode(to: .cost)
        switchMode(to: .cost, animated: true)
    }

    @objc private func switchToQuantity() {
        //viewModel.switchMode(.quantity)
        viewController?.switchMode(to: .quantity)
        switchMode(to: .quantity, animated: true)
    }

    @objc private func switchToStatus() {
        //viewModel.switchMode(.status)
        viewController?.switchMode(to: .status)
        switchMode(to: .status, animated: true)
    }

    func switchMode(to newMode: KeypadMode, animated: Bool) {
        let unitHeight = frame.height / 3.0

        guard
            let superview = highlightView.superview,
            let top = superview.constraint(withIdentifier: "topAnchor"),
            let bottom = superview.constraint(withIdentifier: "bottomAnchor") else {
                log.warning("Unable to get superview or constraints"); return
        }

        // TODO: move this into `didSet` on `currentMode`?
        switch newMode {
        case .cost:
            costTapGestureRecognizer.isEnabled = false
            quantityTapGestureRecognizer.isEnabled = true
            statusTapGestureRecognizer.isEnabled = true

            top.constant = 0.0
            bottom.constant = 0.0
        case .quantity:
            costTapGestureRecognizer.isEnabled = true
            quantityTapGestureRecognizer.isEnabled = false
            statusTapGestureRecognizer.isEnabled = true

            top.constant = unitHeight
            bottom.constant = unitHeight
        case .status:
            costTapGestureRecognizer.isEnabled = true
            quantityTapGestureRecognizer.isEnabled = true
            statusTapGestureRecognizer.isEnabled = false

            top.constant = 2.0 * unitHeight
            bottom.constant = 2.0 * unitHeight
        }

        switch animated {
        case true:
            animateTransition(toMode: newMode)
        case false:
            updateLabelTextColors(forMode: newMode)
            layoutIfNeeded()
        }
    }

    // MARK: - Animation

    func animateTransition(toMode newMode: KeypadMode) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(animationTimingFunction)

        /// https://stackoverflow.com/a/38436888/4472195
        UIView.transition(
            with: self, duration: animationDuration, options: animationOptions,
            animations: {
                self.updateLabelTextColors(forMode: newMode)

        }, completion: nil)

        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            self?.layoutIfNeeded()
        })

        CATransaction.commit()
    }

    // MARK: - D

    private func updateLabelTextColors(forMode newMode: KeypadMode) {
        costTextLabel.textColor = newMode == .cost ? activeLabelColor : inactiveLabelColor
        quantityTextLabel.textColor = newMode == .quantity ? activeLabelColor : inactiveLabelColor
        quantityUnitView.unitBackgroundColor = newMode == .quantity ? activeBackgroundColor : inactiveBackgroundColor
        quantityUnitView.unitBorderColor = newMode == .quantity ? activeLabelColor : inactiveLabelColor
        statusTextLabel.textColor = newMode == .status ? activeLabelColor : inactiveLabelColor
    }

}

// MARK: - HighlightView

class InvoiceDisplayHighlightView: UIView {

    var indicatorColor: UIColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.35)
    var indicatorWidth: CGFloat = 2.0
    var indicatorVerticalInset: CGFloat = 7.0
    var indicatorHorizontalInset: CGFloat = 13.0

    private var indicatorLayer: CAShapeLayer

    // MARK: - Lifecycle

    public init() {
        self.indicatorLayer = CAShapeLayer()
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 50))
        self.configure()
    }

    override init(frame: CGRect) {
        self.indicatorLayer = CAShapeLayer()
        super.init(frame: frame)
        self.configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: - B

    //override func layoutIfNeeded() {}

    override func layoutSubviews() {
        super.layoutSubviews()

        let x: CGFloat = frame.width - indicatorWidth - indicatorHorizontalInset
        let y: CGFloat = indicatorVerticalInset
        // TODO: should height be determined by xHeight of InvoiceDisplaySubview labels?
        let height = frame.height - (2.0 * indicatorVerticalInset)
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: indicatorWidth, height: height), cornerRadius: 1)
        indicatorLayer.path = path.cgPath
    }

    // MARK: - View Methods

    func configure() {
        (configureLayer >>> layer.addSublayer)(indicatorLayer)
    }

    private func configureLayer(_ layer: CAShapeLayer) -> CAShapeLayer {
        layer.fillColor = indicatorColor.cgColor
        layer.strokeColor = indicatorColor.cgColor
        return layer
    }

}
