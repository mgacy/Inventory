//
//  Operators.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/19/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name

precedencegroup AssociativityLeft { associativity: left }

infix operator >>>: AssociativityLeft

/**
 Compose functions.

 - parameter f: function (A) -> B
 - parameter g: function (B) -> C
 - returns: composed function (A) -> B

 Example:

     func square(_ x: Int) -> Int {
        return x * x
     }

     func increment(_ x: Int) -> Int {
        return x + 1
     }

     func describe(_ val: CustomStringConvertible) -> String {
        return "The resulting value is: \(val)"
     }

     (square >>> increment >>> describe)(3)  // "The resulting value is: 10"

 */
func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    return { x in g(f(x)) }
}
