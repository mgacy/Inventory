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

// swiftlint:disable file_length

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

    /// Output
    public var commandProp: StepperCommand {
        didSet {
            sendActions(for: .valueChanged)
        }
    }

    /// Bindable sink for ItemState.
    var itemState: Binder<ItemState> {
        return Binder(self) { control, state in
            control.updateView(for: state)
        }
    }

    private var currentUnit: NewCurrentUnit = .invalidUnit {
        didSet {
            if currentUnit != oldValue {
                unitView.updateUnit(currentUnit.converted())
            }
        }
    }

    // MARK: - Appearance

    let buttonTextColor: UIColor = .black
    let buttonBackgroundColor: UIColor = .clear
    let buttonBorderColor: CGColor = UIColor.black.cgColor
    let buttonBorderWidth: CGFloat = 1.0

    let decrementButtonText: String = "-"
    let incrementButtonText: String = "+"

    let labelTextColor: UIColor = .black
    let labelBackgroundColor: UIColor = .clear
    let labelWidthWeight: CGFloat = 0.5

    let cornerRadius: CGFloat = 0.0

    let borderWidth: CGFloat = 0.0
    let borderColor: UIColor = .clear

    lazy var decrementButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.decrementButtonText, for: .normal)
        button.setTitleColor(self.buttonTextColor, for: .normal)
        button.backgroundColor = self.buttonBackgroundColor
        button.layer.borderColor = buttonBorderColor
        button.layer.borderWidth = buttonBorderWidth

        button.addTarget(self, action: #selector(MGStepper.decrementButtonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(MGStepper.buttonTouchUp), for: .touchCancel)
        return button
    }()

    lazy var incrementButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.incrementButtonText, for: .normal)
        button.setTitleColor(self.buttonTextColor, for: .normal)
        button.backgroundColor = self.buttonBackgroundColor
        button.layer.borderColor = buttonBorderColor
        button.layer.borderWidth = buttonBorderWidth

        button.addTarget(self, action: #selector(MGStepper.incrementButtonTouchDown), for: .touchDown)
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

    lazy var unitView: UnitView = {
        let view = UnitView()
        //view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    /// Timer used for autorepeat option.
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
        super.init(frame: CGRect(x: 0, y: 0, width: 120, height: 30))
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.commandProp = .stabilize
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - View Methods

    func setup() {
        addSubview(label)
        addSubview(unitView)
        addSubview(decrementButton)
        addSubview(incrementButton)

        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // View
        let stepperWidth = bounds.size.width
        let stepperHeight = bounds.size.height
        let centerX = stepperWidth / 2.0
        let centerY = stepperHeight / 2.0

        let labelWidth: CGFloat = 24.0
        let labelWidthWeight: CGFloat = 0.5
        let buttonWidth = stepperWidth * ((1 - labelWidthWeight) / 2)

        // Label
        let labelX: CGFloat = centerX - (labelWidth / 2.0)
        label.frame = CGRect(x: labelX, y: 0, width: labelWidth, height: stepperHeight)

        // UnitView
        let unitViewWidth: CGFloat = 18.0
        let unitY = centerY - (unitViewWidth / 2)
        unitView.frame = CGRect(x: labelX + labelWidth, y: unitY, width: unitViewWidth, height: unitViewWidth)
        /*
        // Buttons (Rectangular)
        decrementButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: stepperHeight)
        incrementButton.frame = CGRect(x: stepperWidth - buttonWidth, y: 0, width: buttonWidth, height: stepperHeight)
        */

        // Buttons (Round)
        let buttonY = centerY - (buttonWidth / 2.0)
        decrementButton.frame = CGRect(x: 0, y: buttonY, width: buttonWidth, height: buttonWidth)
        decrementButton.layer.cornerRadius = buttonWidth / 2.0
        incrementButton.frame = CGRect(x: stepperWidth - buttonWidth, y: buttonY, width: buttonWidth,
                                       height: buttonWidth)
        incrementButton.layer.cornerRadius = buttonWidth / 2.0
    }

    // MARK: - E

    func updateValue(command: StepperCommand) {
        commandProp = command
    }

    func updateView(for itemState: ItemState) {
        label.text = itemState.valueString
        switch itemState.stepperState {
        case .initial:
            unitView.updateUnit(itemState.currentUnit.converted(), animated: false)
            // TODO: disable increment / decrement button if .maximumValue / minimumValue
            return
        case .minimum:
            animateLimitHitForButton(button: decrementButton)
        case .maximum:
            animateLimitHitForButton(button: incrementButton)
        default:
            break
        }
        currentUnit = itemState.currentUnit
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
        decrementButton.isEnabled = true
        incrementButton.isEnabled = true

        UIView.animate(withDuration: self.limitHitAnimationDuration, animations: {
            self.decrementButton.backgroundColor = self.buttonBackgroundColor
            self.incrementButton.backgroundColor = self.buttonBackgroundColor
        })
    }

}

// MARK: Button Events
extension MGStepper {

    @objc func decrementButtonTouchDown(button: UIButton) {
        incrementButton.isEnabled = false
        resetTimer()
        updateValue(command: .decrement(stepValue))
        if autorepeat {
            scheduleTimer()
        }
    }

    @objc func incrementButtonTouchDown(button: UIButton) {
        decrementButton.isEnabled = false
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

// TODO: rename `InternalStepperState`
enum StepperState {
    indirect case initial(StepperState)
    case stable
    case shouldIncrement(Int)
    case maximum
    case shouldDecrement(Int)
    case minimum
}

extension StepperState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .initial(let initialState):
            return "<StepperState: INITIAL: \(initialState)>"
        case .stable:
            return "<StepperState: STABLE)>"
        case .shouldIncrement(let stepSize):
            return "<StepperState: + \(stepSize)>"
        case .maximum:
            return "<StepperState: MAX)>"
        case .shouldDecrement(let stepSize):
            return "<StepperState: - \(stepSize)>"
        case .minimum:
            return "<StepperState: MIN)>"
        }
    }
}

extension StepperState: Equatable {

    static func == (lhs: StepperState, rhs: StepperState) -> Bool {
        switch (lhs, rhs) {
        case (.stable, .stable):
            return true
        case (let .shouldIncrement(lhsStepSize), let .shouldIncrement(rhsStepSize)):
            return lhsStepSize == rhsStepSize
        case (.maximum, .maximum):
            return true
        case (let .shouldDecrement(lhsStepSize), let .shouldDecrement(rhsStepSize)):
            return lhsStepSize == rhsStepSize
        case (.minimum, .minimum):
            return true
        default:
            return false
        }
    }

}

enum StepperCommand {
    case increment(Int)
    case decrement(Int)
    //case repeated
    case stabilize
    case switchToPackUnit
    case switchToSingleUnit
}

// TODO: rename `StepperState`
struct ItemState {
    var stepperState: StepperState

    var valueString: String {
        return String(describing: value)
        //return item.quantity != nil ? String(describing: item.quantity!) : "?"
    }

    private var item: UnitToggleable
    private var packSize: Int
    //private var packSize: Int {
    //    return something.associatedItem.packSize
    //}

    var currentUnit: NewCurrentUnit {
        return item.currentUnit
    }

    private var value: Int {
        get {
            //return Int(truncating: something.quantity)
            return item.quantity != nil ? Int(truncating: item.quantity!) : 0
        }
        set {
            item.quantity = newValue as NSNumber
        }
    }

    // B
    private static let threshold: Double = 0.5
    private static let minimumValue: Int = 0
    private static let maximumValue: Int = 99

    init(item: UnitToggleable) {
        self.item = item
        self.packSize = Int(item.associatedItem.packSize)

        let initialState: StepperState
        // https://stackoverflow.com/a/44474754/4472195
        switch Int(truncating: item.quantity ?? ItemState.minimumValue as NSNumber) {
        case Int.min ... ItemState.minimumValue:
            initialState = .minimum
        case ItemState.maximumValue ... Int.max:
            initialState = .maximum
        default:
            initialState = .stable
        }
        self.stepperState = .initial(initialState)
    }

}

extension ItemState {

    // swiftlint:disable:next function_body_length
    static func reduce(state: ItemState, command: StepperCommand) -> ItemState {
        //log.verbose("command: \(command) | state: \(state)")
        switch (state.stepperState, command) {
        case (_, .stabilize):
            return state.mutateOne { $0.stepperState = .stable }

        // Change StepperState
        // Initial ->
        case (.initial(let initialState), _):
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = initialState }, command: command)
        // Stable ->
        case (.stable, .increment(let stepSize)):
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldIncrement(stepSize) },
                                    command: .increment(stepSize))
        case (.stable, .decrement(let stepSize)):
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldDecrement(stepSize) },
                                    command: .decrement(stepSize))
        // Increment / Decrement) ->
        case (.shouldDecrement, .increment(let stepSize)):
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldIncrement(stepSize) },
                                    command: .increment(stepSize))
        case (.shouldIncrement, .decrement(let stepSize)):
            return ItemState.reduce(state: state.mutateOne { $0.stepperState = .shouldDecrement(stepSize) },
                                    command: .decrement(stepSize))

        // Command: Increment / Decrement
        case (.shouldIncrement, .increment(let stepSize)):
            switch state.currentUnit {
            case .singleUnit:
                // See if we can change unit
                if
                    state.packSize > 1,
                    Double(state.value) > threshold * Double(state.packSize),
                    state.item.associatedItem.purchaseUnit != nil
                {
                    log.debug("Changing to case ...")
                    return ItemState.reduce(state: state, command: .switchToPackUnit)
                } else {
                    return state.mutateOne { $0.value += stepSize }
                }
            default:
                // TODO: should we distinguish .packUnit from .invalidUnit?
                guard state.value < maximumValue else {
                    return state.mutateOne { $0.stepperState = .maximum }
                }
                return state.mutateOne { $0.value += stepSize }
            }
        case (.shouldDecrement, .decrement(let stepSize)):
            switch state.currentUnit {
            case .packUnit:
                // Requirements to switchUnit
                if state.value == 1, state.packSize > 1, state.item.associatedItem.purchaseSubUnit != nil {
                    log.debug("Changing to bottle ...")
                    return ItemState.reduce(state: state, command: .switchToSingleUnit)
                }

                guard state.value > minimumValue else {
                    return state.mutateOne { $0.stepperState = .minimum }
                }
                return state.mutateOne { $0.value -= stepSize }
            default:
                guard state.value > minimumValue else {
                    return state.mutateOne { $0.stepperState = .minimum }
                }
                return state.mutateOne { $0.value -= stepSize }
            }

        // Command: Switch Unit
        case (.shouldIncrement, .switchToPackUnit):
            // TODO: verify .currentUnit == .singleUnit?
            return state.mutate {
                $0.value = 1
                $0.item.switchToPackUnit()
            }

        case (.shouldDecrement(let stepSize), .switchToSingleUnit):
            // TODO: verify .currentUnit == .packUnit?
             // TODO: include check that packSize > 0?
            return state.mutate {
                $0.value = $0.packSize - stepSize
                $0.item.switchToSingleUnit()
            }

        // TODO: add support for (.stable, .switchToPackUnit) / (.stable, .switchToSingleUnit)?

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
            log.error("Uncaptured command: \(command) - \(state.stepperState)")
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
