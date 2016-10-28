//
//  Keypad.swift
//  Playground
//
//  Created by Mathew Gacy on 10/11/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation

class Keypad {
    
    let numberFormatter: NumberFormatter
    
    // State
    var isEditingNumber: Bool
    var currentNumber: String
    
    // MARK: - Lifecycle
    
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
        // Try to clear from currentNumber
        if !currentNumber.isEmpty {
            currentNumber.remove(at: currentNumber.index(before: currentNumber.endIndex))
            
            if currentNumber.isEmpty {
                // We just consumed the currentNumber
                isEditingNumber = false
            } else {
                isEditingNumber = true
            }
            
            updateDisplay(button: "clear")
        }
    }
    
    func pushDecimal() {
        isEditingNumber = true
        
        // Add leading '0'
        if currentNumber.isEmpty {
            currentNumber = "0."
            
            // Append decimal point if not already there
        } else if currentNumber.range(of: ".") == nil {
            currentNumber += "."
        }
        
        updateDisplay(button: ".")
    }
    
    func pushDigit(value: Int) {
        if isEditingNumber {
            // TODO - prevent '00'
            // TODO - prevent 'x.yzn'; add setting for max significant digits
            currentNumber += "\(value)"
            
        } else {
            currentNumber = "\(value)"
            isEditingNumber = true
        }
        
        updateDisplay(button: String(value))
    }
    
    // MARK: - Output
    
    func evaluateNumber() -> Double {
        if let value = Double(currentNumber) {
            return value
        } else {
            return 0.0
        }
    }
    
    func _updateNumber(_ newNumber: Double?) {
        guard let _newNumber = newNumber else {
            currentNumber = ""
            return
        }
        
        if let newString = numberFormatter.string(from:  NSNumber(value: _newNumber)) {
            currentNumber = newString
        } else {
            // Is it possible to reach this point?
            print("There was a problem converting '\(_newNumber)' to a string")
            currentNumber = "Error"
        }
    }
    
    func updateNumber(_ newNumber: Double?) {
        // This allows us to override updateNumber in subclasses with additional
        // functionality while still making use of _updateNumber
        // TODO: should this be done using an extension?
        _updateNumber(newNumber)
    }
    
    // MARK: - Testing
    
    func updateDisplay(button: String) {
        print("Pressed '\(button)' - currentNumber: \(currentNumber)")
    }
}

class KeypadWithHistory: Keypad {
    
    // State
    // isEditingNumber
    // currentNumber
    
    var stack: [String] = []
    /*
     var history: String {
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
     */
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        self.stack = []
        
        // TODO - override settings for numberFormatter?
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
                // currentNumber = String(numberStack.popLast()!)
                currentNumber = stack.popLast()!
                isEditingNumber = true
            }
        }
        
        updateDisplay(button: "clear")
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
        
        updateDisplay(button: "+")
    }
    
    // MARK: - B
    
    override func updateNumber(_ newNumber: Double?) {
        stack = []
        _updateNumber(newNumber)
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
        func evaluateStack() -> Double {
            var total = 0.0
            if !stack.isEmpty{
                for item in stack {
                    /*
                     TODO - replace `evaluateNumber()` with .string(from:) and use
                     that here?
                     */
                    if let number = Double(item) {
                        total += number
                    }
                }
            }
            return total
        }
        
        /*
         let a = evaluateNumber()
         print("Number: \(a)")
         let b = evaluateStack()
         print("Stack: \(b)")
         */
        
        let total = evaluateNumber() + evaluateStack()
        return total
    }
    
    func formatTotal(_ result: Double) -> String {
        if let resultString = self.numberFormatter.string(from: NSNumber(value: result)) {
            return resultString
        } else {
            return ""
        }
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
        }
        
        return (history: history, total: total, display: display)
    }
    
    // MARK: - Testing
    
    override func updateDisplay(button: String) {
        print("Pressed '\(button)' - stack: '\(stack.description)' - currentNumber: '\(currentNumber)'")
    }
}
