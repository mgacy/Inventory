//
//  Keypad.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/11/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation

protocol KeypadType {
    var displayValue: String { get }
    var delegate: KeypadDelegate? { get set }

    func popItem()
    func pushDecimal()
    func pushDigit(_: Int)
    func updateNumber(_: NSNumber?)
}

protocol KeypadWithHistoryType: KeypadType {
    var displayHistory: String { get }

    func pushOperator()
}

protocol KeypadDelegate: class {
    func updateModel(_: NSNumber?)
}

class Keypad: KeypadType {

    // TODO: rename `currentDisplay` to better differentiate purpose from currentValue?
    public var displayValue: String {
        // swiftlint:disable:next identifier_name
        guard let _currentNumber = currentNumber else {
            return "?"
        }
        return _currentNumber
    }
    public var currentValue: NSNumber? {
        // swiftlint:disable:next identifier_name
        guard let _currentNumber = currentNumber else {
            return nil
        }
        if let value = numberFormatter.number(from: _currentNumber) {
            return value
        } else {
            return nil
        }
    }

    weak var delegate: KeypadDelegate?

    private let numberFormatter: NumberFormatter
    private let maximumFractionDigits: Int

    // State
    private var isEditingNumber: Bool
    private var currentNumber: String?

    // MARK: - Lifecycle

    required init(formatter: NumberFormatter, delegate: KeypadDelegate?, maximumFractionDigits: Int = 2) {
        self.maximumFractionDigits = maximumFractionDigits
        self.isEditingNumber = false
        self.currentNumber = ""

        self.numberFormatter = formatter
        self.delegate = delegate
    }

    // MARK: - Stack manipulation

    public func popItem() {
        guard var newNumber = currentNumber else {
            return
        }
        newNumber.remove(at: newNumber.index(before: newNumber.endIndex))
        if newNumber.isEmpty {
            // We just consumed the currentNumber
            currentNumber = nil
            isEditingNumber = false
        } else {
            currentNumber = newNumber
            isEditingNumber = true
        }
        delegate?.updateModel(currentValue)
    }

    public func pushDecimal() {
        if isEditingNumber {
            guard let newNumber = currentNumber else {
                fatalError("\(#function) FAILED : isEditingNumber w/ nil")
            }
            if newNumber.range(of: ".") == nil {
                currentNumber = newNumber + "."
            }
        } else {
            isEditingNumber = true
            currentNumber = "0."
        }

        // Since we currently use `delegate?.updateModel(:)` to update both the model AND view model, call that method
        // even if we are not actually changing the value of the model.
        delegate?.updateModel(currentValue)
    }

    public func pushDigit(_ value: Int) {
        if isEditingNumber {
            guard let newNumber = currentNumber else {
                fatalError("\(#function) FAILED : isEditingNumber w/ nil")
            }
            if newNumber.range(of: ".") == nil {
                // Prevent '0n'
                if newNumber == "0" {
                    currentNumber = "\(value)"
                } else {
                    currentNumber = newNumber + "\(value)"
                }
            } else {
                // Limit significant digits to maximumFractionDigits
                guard let decimalIndex = newNumber.range(of: ".")?.lowerBound else {
                    fatalError("\(#function) FAILED : problem detecting '.'")
                }
                if newNumber[decimalIndex...].count <= maximumFractionDigits {
                    currentNumber = newNumber + "\(value)"
                }
            }
        } else {
            currentNumber = "\(value)"
            isEditingNumber = true
        }
        delegate?.updateModel(currentValue)
    }

    /// Essentially, reset currentNumber with newNumber
    public func updateNumber(_ newNumber: NSNumber?) {
        isEditingNumber = false
        // swiftlint:disable:next identifier_name
        guard let _newNumber = newNumber else {
            currentNumber = nil
            return
        }
        guard let newString = numberFormatter.string(from: _newNumber) else {
            log.error("There was a problem converting '\(_newNumber)' to a string")
            currentNumber = "Error"
            return
        }
        currentNumber = newString
    }

}

// MARK: - History

class KeypadWithHistory: KeypadWithHistoryType {

    // NOTE: when displayHistory = `a + b + c`, stack == ["a", "b"] and currentNumber == "c"

    // TODO: rename `currentDisplay` to better differentiate purpose from currentValue?
    public var displayValue: String {
        guard let total = evaluateHistory(stack: self.stack, currentNumber: self.currentNumber) else {
            return "0"
        }
        return numberFormatter.string(from: NSNumber(value: total)) ?? "Error"
    }

    public var displayHistory: String {
        return formHistoryDisplay(stack: self.stack)
    }

    public var currentValue: NSNumber? {
        guard let total = evaluateHistory(stack: self.stack, currentNumber: self.currentNumber) else {
            return nil
        }
        return total as NSNumber
    }

    weak var delegate: KeypadDelegate?

    // Formatting
    private let historySeparator = " + "
    private let numberFormatter: NumberFormatter
    private let maximumFractionDigits: Int

    // State
    /// NOTE: `isEditingNumber` is equivalent to `currentNumber != nil` except after `.updateNumber(:)`
    private var currentNumber: String?
    private var stack: [String] = []
    private var isEditingNumber: Bool

    // MARK: - Lifecycle

    init(formatter: NumberFormatter, maximumFractionDigits: Int = 2) {
        self.numberFormatter = formatter
        self.maximumFractionDigits = maximumFractionDigits

        self.isEditingNumber = false
        // TODO: should we init with `nil`?
        self.currentNumber = ""
        self.stack = []
    }

    // MARK: - Stack manipulation

    public func popItem() {
        // Try to clear from currentNumber
        if var newNumber = currentNumber {
            newNumber.remove(at: newNumber.index(before: newNumber.endIndex))
            if newNumber.isEmpty {
                // We just consumed the currentNumber
                currentNumber = nil
                isEditingNumber = false
            } else {
                currentNumber = newNumber
                isEditingNumber = true
            }
        } else {
            // Try to clear from stack
            if  !stack.isEmpty {
                currentNumber = stack.popLast()!
                isEditingNumber = true
            }
        }
        delegate?.updateModel(currentValue)
    }

    public func pushOperator() {
        guard let newNumber = currentNumber else {
            return
        }
        switch newNumber {
        case "", ".", "0", "0.":
            break
        default:
            // Remove hanging decimal
            if newNumber.hasSuffix(".") {
                self.popItem()
            }

            stack.append(newNumber)
            //currentNumber = ""
            currentNumber = nil
            isEditingNumber = false

             // Since we currently use `delegate?.updateModel(:)` to update both the model AND view model, call that
             // method even if we are not actually changing the value of the model.
            delegate?.updateModel(currentValue)
        }
    }

    public func pushDecimal() {
        if isEditingNumber {
            guard let newNumber = currentNumber else {
                fatalError("\(#function) FAILED : isEditingNumber w/ nil")
            }
            if newNumber.range(of: ".") == nil {
                currentNumber = newNumber + "."
            }
        } else {
            isEditingNumber = true
            currentNumber = "0."
        }
        // Since we currently use `delegate?.updateModel(:)` to update both the model AND view model, call that method
        // even if we are not actually changing the value of the model.
        delegate?.updateModel(currentValue)
    }

    public func pushDigit(_ value: Int) {
        if isEditingNumber {
            guard let newNumber = currentNumber else {
                fatalError("\(#function) FAILED : isEditingNumber w/ nil")
            }
            if newNumber.range(of: ".") == nil {
                // Prevent '0n'
                if newNumber == "0" {
                    currentNumber = "\(value)"
                } else {
                    currentNumber = newNumber + "\(value)"
                }
            } else {
                // Limit significant digits to maximumFractionDigits
                guard let decimalIndex = newNumber.range(of: ".")?.lowerBound else {
                    fatalError("\(#function) FAILED : problem detecting '.'")
                }
                if newNumber[decimalIndex...].count <= maximumFractionDigits {
                    currentNumber = newNumber + "\(value)"
                }
            }
        } else {
            currentNumber = "\(value)"
            isEditingNumber = true
        }
        delegate?.updateModel(currentValue)
    }

    /// Essentially, reset currentNumber with newNumber
    public func updateNumber(_ newNumber: NSNumber?) {
        // TODO: look at how KeypadWithHistory calls `.pushOperator()` if newNumber != nil after calling `super.updateNumber(newNumber)`
        stack = []
        isEditingNumber = false
        // swiftlint:disable:next identifier_name
        guard let _newNumber = newNumber else {
            currentNumber = nil
            return
        }
        guard let newString = numberFormatter.string(from: _newNumber) else {
            log.error("There was a problem converting '\(_newNumber)' to a string")
            currentNumber = "Error"
            return
        }
        currentNumber = newString

        if newNumber != nil {
            pushOperator()
        }
    }

    // MARK: - Output (w/ History)

    /// Stuff
    ///
    /// - returns: String representation of stack and currentNumber
    private func formHistoryDisplay(stack: [String]) -> String {
        var historyString = ""
        if !stack.isEmpty {
            historyString = stack.joined(separator: historySeparator)
            if currentNumber == nil {
                historyString += historySeparator
            }
        }

        if let someNumber = currentNumber {
            if !stack.isEmpty {
                historyString += historySeparator
            }
            historyString += someNumber
        }

        return historyString
    }

    private func evaluateStack(stack: [String]) -> Double? {
        switch stack.isEmpty {
        case true:
            return nil
        case false:
            return stack.reduce(0.0) { $0 + (Double($1) ?? 0.0) }
        }
    }

    private func evaluateHistory(stack: [String], currentNumber: String?) -> Double? {
        let stackValue = evaluateStack(stack: stack)
        guard
            let someNumber = currentNumber,
            let currentValue = Double(someNumber) else {
                return stackValue
        }

        // currentValue:    Double
        // stackValue:      Double?
        return currentValue + (stackValue ?? 0.0)
    }

}
