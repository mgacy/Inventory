//
//  OrderItemView.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/1/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

// MARK: - Header

final class OrderItemHeaderView: UIView {

    // MARK: - Appearance

    let disabledButtonColor: UIColor = .lightGray
    let dividerColor: UIColor = ColorPalette.dividerColor

    // Views

    lazy var repNameTextLabel: UILabel = {
        let label = UILabel()
        label.text = "John Doe"
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 24.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var messageButton: RoundButton = {
        let button = RoundButton()
        button.setImage(#imageLiteral(resourceName: "SmallMessageButton"), for: .normal)
        button.setBackgroundColor(color: self.tintColor, forState: .normal)
        button.setBackgroundColor(color: disabledButtonColor, forState: .disabled)
        //button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var emailButton: RoundButton = {
        let button = RoundButton()
        button.setImage(#imageLiteral(resourceName: "SmallEmailButton"), for: .normal)
        button.setBackgroundColor(color: self.tintColor, forState: .normal)
        button.setBackgroundColor(color: disabledButtonColor, forState: .disabled)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var callButton: RoundButton = {
        let button = RoundButton()
        button.setImage(#imageLiteral(resourceName: "SmallPhoneButton"), for: .normal)
        button.setBackgroundColor(color: self.tintColor, forState: .normal)
        button.setBackgroundColor(color: disabledButtonColor, forState: .disabled)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageButton, emailButton, callButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 40
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [repNameTextLabel, buttonStackView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.isBaselineRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var bottomDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }

    // MARK: - Configuration

    private func configure() {
        //backgroundColor = .yellow
        addSubview(stackView)
        addSubview(bottomDividerView)
        setupConstraints()
    }

    private func setupConstraints() {
        let constraints = [
            // Buttons
            messageButton.widthAnchor.constraint(equalToConstant: 40.0),
            messageButton.heightAnchor.constraint(equalToConstant: 40.0),
            emailButton.widthAnchor.constraint(equalToConstant: 40.0),
            emailButton.heightAnchor.constraint(equalToConstant: 40.0),
            callButton.widthAnchor.constraint(equalToConstant: 40.0),
            callButton.heightAnchor.constraint(equalToConstant: 40.0),
            // StackView
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomDividerView.topAnchor),
            // Divider
            bottomDividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDividerView.heightAnchor.constraint(equalToConstant: 0.5),
            bottomDividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDividerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - B

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

// MARK: - Footer

final class OrderItemFooterView: UIView {

    // MARK: - Appearance

    // MARK: - Views

    lazy var topDividerView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorPalette.dividerColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var mainTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.text = "Test"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }

    // MARK: - Configuration

    private func configure() {
        //backgroundColor = .cyan
        addSubview(topDividerView)
        addSubview(mainTextLabel)
        setupConstraints()
    }

    private func setupConstraints() {
        let constraints = [
            // topDividerView
            topDividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDividerView.topAnchor.constraint(equalTo: topAnchor),
            topDividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDividerView.heightAnchor.constraint(equalToConstant: 0.5),
            // mainTextLabel
            mainTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            //mainTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            //mainTextLabel.topAnchor.constraint(equalTo: topAnchor),
            //mainTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            //mainTextLabel.bottomAnchor.constraint(equalTo: trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - B

    override func layoutSubviews() {
        super.layoutSubviews()
    }

}
