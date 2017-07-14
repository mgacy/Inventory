//
//  SubItemTableViewCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

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
        /// TESTING: backgroundColor
        //nameTextLabel.backgroundColor = UIColor.red
        //packTextLabel.backgroundColor = UIColor.yellow
        //quantityTextLabel.backgroundColor = UIColor.cyan
        //unitTextLabel.backgroundColor = UIColor.brown

        // Name
        contentView.addSubview(nameTextLabel)

        // Pack
        contentView.addSubview(packTextLabel)
        packTextLabel.font = UIFont.systemFont(ofSize: 12)

        // Quantity
        contentView.addSubview(quantityTextLabel)
        quantityTextLabel.textAlignment = .right

        // Unit
        contentView.addSubview(unitTextLabel)
    }

    func setupConstraints() {
        let marginGuide = contentView.layoutMarginsGuide

        // Name
        nameTextLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
        nameTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        //nameTextLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        nameTextLabel.trailingAnchor.constraint(equalTo: quantityTextLabel.leadingAnchor).isActive = true
        nameTextLabel.numberOfLines = 0

        // Pack
        packTextLabel.translatesAutoresizingMaskIntoConstraints = false
        packTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
        packTextLabel.topAnchor.constraint(equalTo: nameTextLabel.bottomAnchor).isActive = true
        packTextLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        packTextLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor).isActive = true
        packTextLabel.numberOfLines = 1

        // Unit
        unitTextLabel.translatesAutoresizingMaskIntoConstraints = false
        //unitTextLabel.leadingAnchor.constraint(equalTo: quantityTextLabel.trailingAnchor).isActive = true
        unitTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        unitTextLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        unitTextLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        unitTextLabel.numberOfLines = 1

        // Quantity
        quantityTextLabel.translatesAutoresizingMaskIntoConstraints = false
        //quantityTextLabel.leadingAnchor.constraint(equalTo: nameTextLabel.trailingAnchor).isActive = true
        quantityTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        quantityTextLabel.widthAnchor.constraint(equalToConstant: 75).isActive = true
        quantityTextLabel.trailingAnchor.constraint(equalTo: unitTextLabel.leadingAnchor, constant: -5).isActive = true
        quantityTextLabel.numberOfLines = 1
    }

}

// MARK: -

extension SubItemTableViewCell {

    func configure(withViewModel viewModel: SubItemCellViewModel) {
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

// MARK: - ViewModel

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
            return ColorPalette.yellowColor
        case .normal:
            return .black
        case .warning:
            return ColorPalette.redColor
        }
    }
}

protocol SubItemCellViewModel {
    //associatedtype Object: NSManagedObject
    var nameText: String { get }
    var nameColor: UIColor { get }
    var packText: String { get }
    var packColor: UIColor { get }
    var quantityText: String { get }
    var quantityColor: UIColor { get }
    var unitText: String { get }
    var unitColor: UIColor { get }

    //init(for: Object)
}

// MARK: Default Implementations

extension SubItemCellViewModel {
    var packColor: UIColor { return UIColor.lightGray }
}
