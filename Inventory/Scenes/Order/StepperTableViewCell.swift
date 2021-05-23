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

class StepperTableViewCell: UITableViewCell {

    var bindings: StepperCellViewModel.Bindings {
        return StepperCellViewModel.Bindings(
            commands: Driver.of(contextualActionSubject.asDriver(onErrorJustReturn: .stabilize),
                                stepper.rx.commandProp.asDriver(onErrorJustReturn: .stabilize)).merge()
        )
    }
    var viewModel: StepperCellViewModel?

    /*
    var viewModel: StepperCellViewModel? {
        didSet {
            let disposeBag = DisposeBag()
            guard let viewModel = viewModel else {
                return
            }

            nameTextLabel.text = viewModel.nameText
            packTextLabel.text = viewModel.packText
            parTextLabel.text = viewModel.parText
            parUnitView.updateUnit(viewModel.parUnit, animated: false)
            recommendedTextLabel.text = viewModel.recommendedText
            recommendedUnitView.updateUnit(viewModel.recommendedUnit, animated: false)

            let commands = Driver.of(contextualActionSubject.asDriver(onErrorJustReturn: .stabilize),
                                     stepper.rx.commandProp.asDriver(onErrorJustReturn: .stabilize)).merge()

            viewModel.transform(input: commands)
                .drive(stepper.itemState)
                .disposed(by: disposeBag)

            self.disposeBag = disposeBag
        }
    }
    */
    // MARK: - Interface

    let stepper: MGStepper = {
        let stepper = MGStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        return stepper
    }()

    lazy var nameTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        //label.font = UIFont.preferredFont(forTextStyle: .title2)
        //label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var packTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        //label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        //label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Par
    lazy var parLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 10)
        //label.font = UIFont.preferredFont(forTextStyle: .caption2)
        label.textColor = .lightGray
        label.text = "par"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var parTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    lazy var parUnitView: UnitView = {
        let view = UnitView(currentUnit: .singleUnit)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var parQuantityStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [parTextLabel, parUnitView])
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var parStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [parLabel, parQuantityStackView])
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Recommended
    lazy var recommendedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.text = "suggested"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var recommendedTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    lazy var recommendedUnitView: UnitView = {
        let view = UnitView(currentUnit: .singleUnit)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var recommendedQuantityStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [recommendedTextLabel, recommendedUnitView])
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var recommendedStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [recommendedLabel, recommendedQuantityStackView])
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Bottom Stack
    lazy var bottomStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [parStackView, recommendedStackView])
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.alignment = .fill
        view.spacing = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    //private(set) var disposeBag: DisposeBag?
    private(set) var disposeBag = DisposeBag()
    private let contextualActionSubject: PublishSubject<StepperCommand>

    // MARK: - Lifecycle

    // TODO: init with initial state (or view model)?
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        contextualActionSubject = PublishSubject<StepperCommand>()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initViews()
        setupConstraints()
        //colorSubViewBackgrounds()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // because life cycle of every cell ends on prepare for reuse
        self.viewModel = nil
        //self.disposeBag = nil
    }
    /*
    override func setSelected(_ selected: Bool, animated: Bool) {
        switch selected {
        case true:
        // ...
        case false:
            // ...
        }
        super.setSelected(selected, animated: animated)
    }
    */
    // MARK: - View Methods

    private func initViews() {
        contentView.addSubview(nameTextLabel)
        contentView.addSubview(packTextLabel)
        contentView.addSubview(stepper)
        contentView.addSubview(bottomStackView)
    }

    func setupConstraints() {
        let marginGuide = contentView.layoutMarginsGuide

        // Name
        let nameConstraints = [
            nameTextLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor),
            nameTextLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor),
            nameTextLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor)
        ]

        // Pack
        let packConstraints = [
            packTextLabel.leadingAnchor.constraint(equalTo: nameTextLabel.leadingAnchor),
            packTextLabel.topAnchor.constraint(equalTo: nameTextLabel.bottomAnchor),
            packTextLabel.trailingAnchor.constraint(equalTo: nameTextLabel.trailingAnchor)
        ]

        // Stepper
        let stepperConstraints = [
            stepper.topAnchor.constraint(equalTo: marginGuide.topAnchor),
            stepper.widthAnchor.constraint(equalToConstant: 120),
            stepper.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor),
            stepper.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor)
        ]

        // UnitViews
        let unitConstraints = [
            parUnitView.widthAnchor.constraint(equalToConstant: 10.0),
            parUnitView.heightAnchor.constraint(equalToConstant: 10.0),
            recommendedUnitView.widthAnchor.constraint(equalToConstant: 10.0),
            recommendedUnitView.heightAnchor.constraint(equalToConstant: 10.0)
        ]

        // StackView
        let stackViewConstraints = [
            bottomStackView.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor),
            bottomStackView.topAnchor.constraint(equalTo: packTextLabel.bottomAnchor, constant: 10.0),
            bottomStackView.trailingAnchor.constraint(equalTo: contentView.centerXAnchor),
            //bottomStackView.widthAnchor.constraint(equalToConstant: 200.0),
            bottomStackView.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor)
        ]

        for constraints in [nameConstraints, packConstraints, stepperConstraints, unitConstraints,
                            stackViewConstraints] {
            NSLayoutConstraint.activate(constraints)
        }
    }
    /*
    private func colorSubViewBackgrounds() {
        nameTextLabel.backgroundColor = UIColor.red
        packTextLabel.backgroundColor = UIColor.yellow

        parLabel.backgroundColor = UIColor.cyan
        parTextLabel.backgroundColor = UIColor.magenta
        parUnitView.backgroundColor = UIColor.yellow

        //recommendedLabel.backgroundColor = UIColor.cyan
        //recommendedTextLabel.backgroundColor = UIColor.brown
        //recommendedUnitView.backgroundColor = UIColor.yellow

        //stepper.backgroundColor = .blue
        //bottomStackView.backgroundColor = UIColor.magenta
    }
    */
}

// MARK: -

extension StepperTableViewCell {

    func bind(to viewModel: StepperCellViewModel) {
        self.viewModel = viewModel
        // Name
        nameTextLabel.text = viewModel.nameText
        nameTextLabel.textColor = viewModel.nameColor
        // Pack
        packTextLabel.text = viewModel.packText
        // Par
        parTextLabel.text = viewModel.parText
        parUnitView.updateUnit(viewModel.parUnit, animated: false)
        // Recommended
        recommendedTextLabel.text = viewModel.recommendedText
        recommendedUnitView.updateUnit(viewModel.recommendedUnit, animated: false)

        viewModel.state
            .drive(stepper.itemState)
            .disposed(by: disposeBag)
    }

}

// MARK: - Swipe Actions
extension StepperTableViewCell: OrderLocItemActionable {

    func decrement() -> Bool {
        contextualActionSubject.onNext(.decrement(1))
        //contextualActionSubject.onNext(.stabilize)
        return true
    }

    func increment() -> Bool {
        contextualActionSubject.onNext(.increment(1))
        //contextualActionSubject.onNext(.stabilize)
        return true
    }

    func setToPar() -> Bool {
        guard let vm = viewModel, vm.setOrderToPar() else {
            return false
        }
        // FIXME: this is kinda hackish
        contextualActionSubject.onNext(.stabilize)
        return true
    }

    func setToZero() -> Bool {
        guard let vm = viewModel, vm.setOrderToZero() else {
            return false
        }
        // FIXME: this is kinda hackish
        contextualActionSubject.onNext(.stabilize)
        return true
    }

}
