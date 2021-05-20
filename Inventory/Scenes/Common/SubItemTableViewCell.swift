//
//  SubItemTableViewCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

// This is used in view models

enum ItemStatus: String {
    case inactive
    case pending
    case normal
    case warning

    var associatedColor: UIColor {
        switch self {
        case .inactive:
            return .lightGray
        case .pending:
            return ColorPalette.yellow
        case .normal:
            return .black
        case .warning:
            return ColorPalette.red
        }
    }
}

class SubItemTableViewCell: UITableViewCell {

    let nameTextLabel = UILabel()
    let packTextLabel = UILabel()
    let quantityTextLabel = UILabel()
    let unitTextLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
        setupConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initViews() {
        // Name
        contentView.addSubview(nameTextLabel)
        nameTextLabel.numberOfLines = 0
        nameTextLabel.translatesAutoresizingMaskIntoConstraints = false

        // Pack
        contentView.addSubview(packTextLabel)
        packTextLabel.font = UIFont.systemFont(ofSize: 12)
        packTextLabel.numberOfLines = 1
        packTextLabel.translatesAutoresizingMaskIntoConstraints = false

        // Quantity
        contentView.addSubview(quantityTextLabel)
        quantityTextLabel.numberOfLines = 1
        quantityTextLabel.textAlignment = .right
        quantityTextLabel.translatesAutoresizingMaskIntoConstraints = false

        // Unit
        contentView.addSubview(unitTextLabel)
        unitTextLabel.numberOfLines = 1
        unitTextLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupConstraints() {
        let marginGuide = contentView.layoutMarginsGuide

        NSLayoutConstraint.activate([
            // Name
            nameTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor),
            nameTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor),
            //nameTextLabel.widthAnchor.constraint(equalToConstant: 150),
            nameTextLabel.trailingAnchor.constraint(equalTo: quantityTextLabel.leadingAnchor),
            // Pack
            packTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor),
            packTextLabel.topAnchor.constraint(equalTo: nameTextLabel.bottomAnchor),
            packTextLabel.widthAnchor.constraint(equalToConstant: 150),
            packTextLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor),
            // Unit
            //unitTextLabel.leadingAnchor.constraint(equalTo: quantityTextLabel.trailingAnchor),
            unitTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor),
            unitTextLabel.widthAnchor.constraint(equalToConstant: 30),
            unitTextLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor),
            // Quantity
            //quantityTextLabel.leadingAnchor.constraint(equalTo: nameTextLabel.trailingAnchor),
            quantityTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor),
            quantityTextLabel.widthAnchor.constraint(equalToConstant: 75),
            quantityTextLabel.trailingAnchor.constraint(equalTo: unitTextLabel.leadingAnchor, constant: -5)
        ])
    }
    /*
    private func colorSubViewBackgrounds() {
        nameTextLabel.backgroundColor = UIColor.red
        packTextLabel.backgroundColor = UIColor.yellow
        quantityTextLabel.backgroundColor = UIColor.cyan
        unitTextLabel.backgroundColor = UIColor.brown
    }
    */
}

// MARK: -

extension SubItemTableViewCell {

    func configure(withViewModel viewModel: SubItemCellViewModelType) {
        nameTextLabel.text = viewModel.nameText
        nameTextLabel.textColor = viewModel.nameColor
        packTextLabel.text = viewModel.packText
        packTextLabel.textColor = viewModel.packColor
        quantityTextLabel.text = viewModel.quantityText
        quantityTextLabel.textColor = viewModel.quantityColor
        unitTextLabel.text = viewModel.unitText
        unitTextLabel.textColor = viewModel.unitColor
    }

}
