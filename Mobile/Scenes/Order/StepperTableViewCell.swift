//
//  StepperTableViewCell.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/28/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

// MARK: - OrderItemCell

class StepperTableViewCell: UITableViewCell {

    var bindings: StepperCellViewModel.Bindings {
        return StepperCellViewModel.Bindings(
            commands: stepper.rx.commandProp.asDriver(onErrorJustReturn: .stabilize)
            //stepperState: stepper.rx.itemState.asDriver()
        )
    }

    let nameTextLabel = UILabel()
    let packTextLabel = UILabel()
    let quantityTextLabel = UILabel()
    let unitTextLabel = UILabel()

    let stepper: MGStepper = {
        let stepper = MGStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        return stepper
    }()

    private(set) var disposeBag = DisposeBag()

    // MARK: - Lifecycle

    /// TODO: init with initial state (or view model)?
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
        setupConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // because life cicle of every cell ends on prepare for reuse
    }

    // MARK: - View Methods

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
        packTextLabel.textColor = .lightGray

        // Stepper
        contentView.addSubview(stepper)
    }

    func setupConstraints() {
        let marginGuide = contentView.layoutMarginsGuide

        // Name
        nameTextLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
        nameTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        nameTextLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor).isActive = true
        nameTextLabel.numberOfLines = 0

        // Pack
        packTextLabel.translatesAutoresizingMaskIntoConstraints = false
        packTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
        packTextLabel.topAnchor.constraint(equalTo: nameTextLabel.bottomAnchor).isActive = true
        packTextLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        packTextLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor).isActive = true
        packTextLabel.numberOfLines = 1

        // Stepper
        stepper.widthAnchor.constraint(equalToConstant: 120).isActive = true
        stepper.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stepper.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        stepper.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        //stepper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //stepper.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

}

// MARK: -

extension StepperTableViewCell {

    func bind(to viewModel: StepperCellViewModel) {
        /// TODO: simply replace with String properties
        //nameTextLabel.text = viewModel.nameText
        //packTextLabel.text = viewModel.packText

        viewModel.nameText
            .drive(nameTextLabel.rx.text)
            .disposed(by: disposeBag)

        //nameTextLabel.textColor = viewModel.nameColor
        //viewModel.nameColor
        //    .drive(nameTextLabel.rx.textColor)
        //    .disposed(by: disposeBag)

        viewModel.packText
            .drive(packTextLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.state
            .drive(stepper.itemState)
            .disposed(by: disposeBag)
    }

}
