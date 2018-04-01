//
//  MGStepper.swift
//  Mobile
//
//  Created by Mathew Gacy on 3/7/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

/// https://github.com/ReactiveX/RxSwift/issues/991
extension Reactive where Base: MGStepper {

    /// Reactive wrapper for `commandProp` property.
    internal var commandProp: ControlProperty<StepperCommand> {
        return UIControl.valuePublic(
            self.base,
            getter: { customControl in
                customControl.commandProp
        }, setter: { customControl, value in
            customControl.commandProp = value
        }
        )
    }

}

class MGStepper: UIControl {

    // MARK: - A

    public var commandProp: StepperCommand {
        didSet {
            //if oldValue != value {
            sendActions(for: .valueChanged)
            //}
        }
    }

    var itemState: Binder<ItemState> {
        return Binder(self) { control, state in
            //print("UPDATE: \(state)")
            control.updateView(for: state)
        }
    }

    // MARK: - Appearance

    let buttonTextColor: UIColor = .black
    let buttonBackgroundColor: UIColor = .gray
    let leftButtonText: String = "-"
    let rightButtonText: String = "+"

    let labelTextColor: UIColor = .black
    let labelBackgroundColor: UIColor = .white
    let labelWidthWeight: CGFloat = 0.5

    let cornerRadius: CGFloat = 4.0

    let borderWidth: CGFloat = 0.0
    let borderColor: UIColor = .clear

    lazy var leftButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.leftButtonText, for: .normal)
        button.setTitleColor(self.buttonTextColor, for: .normal)
        button.backgroundColor = self.buttonBackgroundColor
        button.addTarget(self, action: #selector(MGStepper.leftButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchCancel)
        return button
    }()

    lazy var rightButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.rightButtonText, for: .normal)
        button.setTitleColor(self.buttonTextColor, for: .normal)
        button.backgroundColor = self.buttonBackgroundColor
        button.addTarget(self, action: #selector(MGStepper.rightButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchCancel)
        return button
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = self.labelTextColor
        label.backgroundColor = self.labelBackgroundColor
        return label
    }()

    lazy var singleUnit: CAShapeLayer = {
        let layer = CAShapeLayer()

        let x = 60.0
        let y = 12.0
        let length = 8.0
        let rectanglePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: length, height: length), cornerRadius: 1)

        // Stroke
        rectanglePath.lineWidth = 1
        rectanglePath.lineJoinStyle = .round

        layer.path = rectanglePath.cgPath
        layer.fillColor = UIColor.white.cgColor
        layer.strokeColor = UIColor.black.cgColor
        return layer
    }()

    lazy var packUnit: CAShapeLayer = {
        let layer = CAShapeLayer()

        let x = 64.0
        let y = 8.0
        let length = 8.0
        let rectanglePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: length, height: length),
                                         cornerRadius: 1)

        // Stroke
        rectanglePath.lineWidth = 1
        rectanglePath.lineJoinStyle = .round

        layer.path = rectanglePath.cgPath
        layer.fillColor = UIColor.white.cgColor
        layer.strokeColor = UIColor.black.cgColor
        return layer
    }()

    // MARK: - Animation

    /// Color of the flashing animation on the buttons in case the value hit the limit.
    public var limitHitAnimationColor: UIColor = .red

    /// Duration of the animation when the value hits the limit.
    let limitHitAnimationDuration = TimeInterval(0.1)

    // MARK: - Function

    /// Step/Increment value as in UIStepper. Defaults to 1.
    let stepValue: Int = 1

    /// The same as UIStepper's autorepeat. If true, holding on the buttons alters the value repeatedly. Defaults to true.
    let autorepeat: Bool = true

    /// Timer used for autorepeat option
    var timer: Timer?

    /** When UIStepper reaches its top speed, it alters the value with a time interval of ~0.05 sec.
     The user pressing and holding on the stepper repeatedly:
     - First 2.5 sec, the stepper changes the value every 0.5 sec.
     - For the next 1.5 sec, it changes the value every 0.1 sec.
     - Then, every 0.05 sec.
     */
    let timerInterval = TimeInterval(0.05)

    /// Check the handleTimerFire: function. While it is counting the number of fires, it decreases the mod value so that the value is altered more frequently.
    var timerFireCount = 0
    var timerFireCountModulo: Int {
        if timerFireCount > 80 {
            return 1 // 0.05 sec * 1 = 0.05 sec
        } else if timerFireCount > 50 {
            return 2 // 0.05 sec * 2 = 0.1 sec
        } else {
            return 10 // 0.05 sec * 10 = 0.5 sec
        }
    }

    // MARK: - Lifecycle

    public init() {
        self.commandProp = .stabilize
        super.init(frame: CGRect (x: 0, y: 0, width: 100, height: 30))
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.commandProp = .stabilize
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - D

    func setup() {
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(label)

        // B
        layer.addSublayer(singleUnit)
        layer.addSublayer(packUnit)

        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }

    override func layoutSubviews() {
        let labelWidthWeight: CGFloat = 0.5

        let buttonWidth = bounds.size.width * ((1 - labelWidthWeight) / 2)
        let labelWidth = bounds.size.width * labelWidthWeight

        leftButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.size.height)
        label.frame = CGRect(x: buttonWidth, y: 0, width: labelWidth, height: bounds.size.height)
        rightButton.frame = CGRect(x: labelWidth + buttonWidth, y: 0, width: buttonWidth, height: bounds.size.height)
    }

    // MARK: - E

    func updateValue(command: StepperCommand) {
        commandProp = command
    }

    func updateView(for itemState: ItemState) {
        label.text = String(itemState.value)
        switch itemState.currentUnit {
        case .singleUnit:
            packUnit.isHidden = true
        case .packUnit:
            packUnit.isHidden = false
        case .invalidUnit:
            print("INVALID")
        }

        if itemState.stepperState == .minimum {
            animateLimitHitForButton(button: leftButton)
        } else if itemState.stepperState == .maximum {
            animateLimitHitForButton(button: rightButton)
        }

    }

    deinit {
        resetTimer()
    }

}

// MARK: - ?
extension MGStepper {

    @objc func reset() {
        updateValue(command: .stabilize)
        resetTimer()
        leftButton.isEnabled = true
        rightButton.isEnabled = true

        UIView.animate(withDuration: self.limitHitAnimationDuration, animations: {
            //self.label.center = self.labelOriginalCenter
            self.rightButton.backgroundColor = self.buttonBackgroundColor
            self.leftButton.backgroundColor = self.buttonBackgroundColor
        })
    }

}

// MARK: Button Events
extension MGStepper {

    @objc func leftButtonTouchDown(button: UIButton) {
        rightButton.isEnabled = false
        resetTimer()
        updateValue(command: .decrement(stepValue))
        if autorepeat {
            scheduleTimer()
        }
    }

    @objc func rightButtonTouchDown(button: UIButton) {
        leftButton.isEnabled = false
        resetTimer()
        updateValue(command: .increment(stepValue))
        if autorepeat {
            scheduleTimer()
        }
    }

    @objc func buttonTouchUp(button: UIButton) {
        reset()
    }

}

// MARK: Animations
extension MGStepper {

    func animateLimitHitForButton(button: UIButton) {
        UIView.animate(withDuration: limitHitAnimationDuration) {
            button.backgroundColor = self.limitHitAnimationColor
        }
    }

}

// MARK: - Timer
extension MGStepper {

    @objc func handleTimerFire(timer: Timer) {
        timerFireCount += 1
        if timerFireCount % timerFireCountModulo == 0 {
            sendActions(for: .valueChanged)
        }
    }

    func scheduleTimer() {
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self,
                                     selector: #selector(MGStepper.handleTimerFire), userInfo: nil, repeats: true)
    }

    func resetTimer() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
            timerFireCount = 0
        }
    }

}

// MARK: - A

//let stepSize = 1

enum StepperState {
    case stable
    case shouldIncrement(Int)
    case maximum
    case shouldDecrement(Int)
    case minimum
}

extension StepperState: Equatable {

    static func == (lhs: StepperState, rhs: StepperState) -> Bool {
        switch (lhs, rhs) {
        case (.stable, .stable):
            return true
        case (let .shouldIncrement(stepSize1), let .shouldIncrement(stepSize2)):
            return stepSize1 == stepSize2
        case (.maximum, .maximum):
            return true
        case (let .shouldDecrement(stepSize1), let .shouldDecrement(stepSize2)):
            return stepSize1 == stepSize2
        case (.minimum, .minimum):
            return true
        default:
            return false
        }
    }

}

enum StepperCommand {
    //case reset(Int, Int, CurrentUnit)  // quantity, packSize, currentUnit
    case increment(Int)
    case decrement(Int)
    //case repeated
    case stabilize
    case switchToPackUnit
    case switchToSingleUnit
}

struct ItemState {
    var stepperState: StepperState
    var value: Int
    var currentUnit: CurrentUnit
    //var units: ItemUnits

    private var packSize: Int
    // B
    private static let threshold: Double = 0.5
    private static let minimumValue: Int = 0
    private static let maximiumValue: Int = 99

    init(value: Int, packSize: Int, currentUnit: CurrentUnit) {
        self.stepperState = .stable
        self.value = value
        self.packSize = packSize
        self.currentUnit = currentUnit
    }

}

extension ItemState {

    static func reduce(state: ItemState, command: StepperCommand) -> ItemState {
        //print("command: \(command) | state: \(state)")
        switch (state.stepperState, command) {
        case (_, .stabilize):
            return state.mutateOne { $0.stepperState = .stable }

        // A1
        case (.stable, .increment(let stepSize)):
            /// TODO: verify not at maximum?
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldIncrement(stepSize) },
                                    command: .increment(stepSize))
        case (.stable, .decrement(let stepSize)):
            /// TODO: verify not at minimum?
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldDecrement(stepSize) },
                                    command: .decrement(stepSize))
        // A2
        case (.shouldDecrement, .increment(let stepSize)):
            /// TODO: verify not at maximum?
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldIncrement(stepSize) },
                                    command: .increment(stepSize))

        case (.shouldIncrement, .decrement(let stepSize)):
            /// TODO: verify not at minimum?
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldDecrement(stepSize) },
                                    command: .decrement(stepSize))

        // B
        case (.shouldIncrement, .increment(let stepSize)):
            switch state.currentUnit {
            case .singleUnit:
                /// TODO: verify state.units.packUnit != nil,
                /// TODO: is this use of guard really the best way to express our intent?
                guard Double(state.value) > threshold * Double(state.packSize) else {
                    return state.mutateOne { $0.value += stepSize }
                }
                print("Changing to case")
                return ItemState.reduce(state: state, command: .switchToPackUnit)

            default:
                guard state.value < maximiumValue else {
                    return state.mutateOne { $0.stepperState = .maximum }
                }
                return state.mutateOne { $0.value += stepSize }
            }
        case (.shouldDecrement, .decrement(let stepSize)):
            switch state.currentUnit {
            case .packUnit:
                /// TODO: verify state.units.singleUnit != nil,
                /// TODO: is this use of guard really the best way to express our intent?
                guard state.value == 1 else {
                    return state.mutateOne { $0.value -= stepSize }
                }

                print("Changing to bottle")
                return ItemState.reduce(state: state, command: .switchToSingleUnit)

            default:
                guard state.value > minimumValue else {
                    return state.mutateOne { $0.stepperState = .minimum }
                }
                return state.mutateOne { $0.value -= stepSize }
            }

        // C
        case (.shouldIncrement, .switchToPackUnit):
            /// TODO: verify .currentUnit == .singleUnit?
            return state.mutate {
                $0.value = 1
                $0.currentUnit = .packUnit
            }

        case (.shouldDecrement(let stepSize), .switchToSingleUnit):
            /// TODO: verify .currentUnit == .packUnit?
            return state.mutate {
                $0.value = $0.packSize - stepSize
                $0.currentUnit = .singleUnit
            }

        // E
        case (.minimum, .decrement):
            return state
        case (.maximum, .increment):
            return state

        /*
        // D
        //case (.shouldIncrement(let stepSize), .repeated):
        case (.shouldIncrement, .repeated):
            //return state.mutateOne { $0.value += stepSize }
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .stable }, command: .increment(stepSize))
        case (.shouldDecrement, .repeated):
            //return state.mutateOne { $0.value -= stepSize }
            return ItemState.reduce(state: state, command: .decrement(stepSize))
        */
        default:
            print("Uncaptured command: \(command) - \(state.stepperState)")
            return state
        }
    }

}

extension ItemState: Mutable {}

extension ItemState: Equatable {

    public static func == (lhs: ItemState, rhs: ItemState) -> Bool {
        return lhs.value == rhs.value &&
            lhs.currentUnit == rhs.currentUnit
    }

    public static func != (lhs: ItemState, rhs: ItemState) -> Bool {
        return lhs.value != rhs.value ||
            lhs.currentUnit != rhs.currentUnit
    }

}

// MARK: - View
/*
// https://stackoverflow.com/a/41928756/4472195
class TestView: UIView {

    var bindings: TestViewModel.Bindings {
        return TestViewModel.Bindings(
            commands: stepper.rx.commandProp.asDriver(onErrorJustReturn: .stabilize)
        )
    }

    // MARK: Interface
    lazy var nameTextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        //label.textColor = self.labelTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var packTextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let stepper: MGStepper = {
        let stepper = MGStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        return stepper
    }()

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 50))
        setupView()
        //setupBindings()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: - View Methods

    func setupView() {
        backgroundColor = UIColor.white
        initSubViews()
        setupConstraints()
    }

    func initSubViews() {
        addSubview(stepper)
        addSubview(nameTextLabel)
        addSubview(packTextLabel)
    }

    func setupConstraints() {
        //let marginGuide = contentView.layoutMarginsGuide
        let marginGuide = self.layoutMarginsGuide

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
        stepper.widthAnchor.constraint(equalToConstant: 100).isActive = true
        stepper.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stepper.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        stepper.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
    }

    //func setupBindings() {}

}

extension TestView {

    func bind(to viewModel: TestViewModel) {
        /// TODO: simply replace with String properties
        //nameTextLabel.text = viewModel.nameText
        //packTextLabel.text = viewModel.packText

        viewModel.nameText
            .drive(nameTextLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.packText
            .drive(packTextLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.state
            .drive(stepper.itemState)
            .disposed(by: disposeBag)
    }

}

// MARK: - ViewModel

final class TestViewModel {

    // MARK: - Properties

    // MARK: Private
    private var orderItem: OrderItem
    private let item: Item

    // MARK: Public
    let state: Driver<ItemState>
    let nameColor: Driver<UIColor>
    let nameText: Driver<String>
    let packText: Driver<String>
    //let quantityColor: Driver<String>
    //let quantityText: Driver<String>

    // MARK: - Lifecycle

    init?(forOrderItem orderItem: OrderItem, bindings: Bindings) {
        self.orderItem = orderItem
        guard let item = orderItem.item else { return nil }
        self.item = item

        self.nameColor = Driver.just(UIColor.black)
        self.nameText = Driver.just(item.name)

        //self.packText = Driver.just(item.packDisplay)
        self.packText = Driver.just("12 x 1000ml")

        let state0 = ItemState(value: Int(orderItem.quantity ?? 0.0),
                               packSize: orderItem.item?.packSize ?? 0,
                               currentUnit: .packUnit)

        self.state = bindings.commands.scan(state0, accumulator: ItemState.reduce)
            //.distinctUntilChanged()
            .filter { $0.stepperState != StepperState.stable }
            .do(onNext: { state in
                print("\n\(state)")
                guard state.stepperState != .maximum, state.stepperState != .minimum else {
                    return
                }
                print("BEFORE: \(orderItem.quantity)")
                orderItem.quantity = Double(state.value)
                print("AFTER: \(orderItem.quantity)")
            })
            .startWith(state0)
    }

    // MARK: -

    struct Dependency {
        let orderItem: OrderItem
    }

    struct Bindings {
        let commands: Driver<StepperCommand>
    }

}
*/
