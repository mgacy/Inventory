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

    func popItem()
    func pushDecimal()
    func pushDigit(_: Int)
    func updateNumber(_: NSNumber?)
}

protocol KeypadDelegate: class {
    //var keypad: NewKeypad { get }
    //func pushDigit(value: Int)
    //func pushDecimal()
    //func popItem()
    //func updateDisplay()
    func updateModel(_: NSNumber?)
}

class NewKeypad: KeypadType {

    /// TODO: rename `currentDisplay` to better differentiate purpose from currentValue?
    public var displayValue: String {
        guard let _currentNumber = currentNumber else {
            return "?"
        }
        return _currentNumber
    }
    public var currentValue: NSNumber? {
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
        /*
         Since we currently use `delegate?.updateModel(:)` to update both the model AND view model, call that method
         even if we are not actually changing the value of the model.
         */
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
                    fatalError("\(#function) FAILED: problem detecting '.'")
                }
                if newNumber.substring(from: decimalIndex).characters.count <= maximumFractionDigits {
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

// MARK: -

class Keypad {

    let numberFormatter: NumberFormatter

    // State
    var isEditingNumber: Bool
    var currentNumber: String

    var display: String {
        if let total = evaluateNumber() {
            return formatTotal(total)
        } else {
            return "0"
        }
    }

    // MARK: - Lifecycle

    /// TODO: pass NumberFormatter?
    init() {
        self.isEditingNumber = false
        self.currentNumber = ""

        // Set up formatter
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.numberStyle = .decimal
        self.numberFormatter.roundingMode = .halfUp
        self.numberFormatter.maximumFractionDigits = 2
    }

    // MARK: - Stack manipulation

    func popItem() {
        if !currentNumber.isEmpty {
            currentNumber.remove(at: currentNumber.index(before: currentNumber.endIndex))

            if currentNumber.isEmpty {
                // We just consumed the currentNumber
                isEditingNumber = false
            } else {
                isEditingNumber = true
            }
        }
    }

    func pushDecimal() {
        isEditingNumber = true

        if currentNumber.isEmpty {
            // Add leading '0'
            currentNumber = "0."
        } else if currentNumber.range(of: ".") == nil {
            // Append decimal point if not already there
            currentNumber += "."
        }
    }

    func pushDigit(value: Int) {
        if isEditingNumber {
            /// TODO: prevent '00'
            /// TODO: prevent 'x.yzn'; add setting for max significant digits
            currentNumber += "\(value)"

        } else {
            currentNumber = "\(value)"
            isEditingNumber = true
        }
    }

    func updateNumber(_ newNumber: Double?) {
        guard let _newNumber = newNumber else {
            currentNumber = ""
            return
        }

        if let newString = numberFormatter.string(from: NSNumber(value: _newNumber)) {
            currentNumber = newString
        } else {
            // Is it possible to reach this point?
            log.error("There was a problem converting '\(_newNumber)' to a string")
            currentNumber = "Error"
        }
    }

    // MARK: - Output

    func evaluateNumber() -> Double? {
        if let value = Double(currentNumber) {
            return value
        } else {
            return nil
        }
    }

    func formatTotal(_ result: Double) -> String {
        if let resultString = self.numberFormatter.string(from: NSNumber(value: result)) {
            return resultString
        } else {
            return ""
        }
    }

}

class KeypadWithHistory: Keypad {

    // State
    // isEditingNumber
    // currentNumber

    var stack: [String] = []

    //var history: String {
    //    return formHistory()
    //}

    // MARK: - Lifecycle

    override init() {
        super.init()

        self.stack = []

        /// TODO: override settings for numberFormatter?
    }

    // MARK: - Stack Manipulation

    override func popItem() {
        // Try to clear from currentNumber
        if !currentNumber.isEmpty {
            currentNumber.remove(at: currentNumber.index(before: currentNumber.endIndex))

            if currentNumber.isEmpty {
                // We just consumed the currentNumber
                isEditingNumber = false
            } else {
                isEditingNumber = true
            }

        } else {

            // Try to clear from stack
            if  !stack.isEmpty {
                currentNumber = stack.popLast()!
                isEditingNumber = true
            }
        }
    }

    func pushOperator() {
        switch currentNumber {
        case "", ".", "0", "0.":
            break
        default:
            // Remove hanging decimal
            if currentNumber.hasSuffix(".") {
                self.popItem()
            }

            stack.append(currentNumber)
            currentNumber = ""
            isEditingNumber = false
        }
    }

    // MARK: - B

    override func updateNumber(_ newNumber: Double?) {
        stack = []
        super.updateNumber(newNumber)
        if newNumber != nil {
            pushOperator()
        }
    }

    // MARK: - Output

    /// <#Description#>
    ///
    /// - returns: String representation of stack and currentNumber
    func formHistory() -> String {

        // Formatting
        let historySeparator = " + "

        var historyString = ""
        if !stack.isEmpty {
            historyString = stack.joined(separator: historySeparator)
            if currentNumber.isEmpty {
                historyString += historySeparator
            }
        }

        if !currentNumber.isEmpty {
            if !stack.isEmpty {
                historyString += historySeparator
            }
            historyString += currentNumber
        }

        return historyString
    }

    func evaluateHistory() -> Double? {

        // Handle stack
        func evaluateStack() -> Double? {
            switch stack.isEmpty {
            case true:
                return nil
            case false:
                var total = 0.0
                for item in stack {
                    /// TODO: replace `evaluateNumber()` with `.string(from:)` and use that here?
                    if let number = Double(item) {
                        total += number
                    }
                }
                return total
            }
        }

        var total: Double? = nil

        if let stackVal = evaluateStack() {
            total = stackVal
        }

        if let numberVal = evaluateNumber() {
            if total != nil {
                total! += numberVal
            } else {
                total = numberVal
            }
        }

        return total
    }

    func output() -> (history: String, total: Double?, display: String) {
        // History
        let history = self.formHistory()
        // Result
        let total = evaluateHistory()
        // Display
        var display = ""
        if total != nil {
            display = formatTotal(total!)
        } else {
            display = "0"
        }
        return (history: history, total: total, display: display)
    }

}
