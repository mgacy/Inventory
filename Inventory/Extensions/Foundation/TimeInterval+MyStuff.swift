//
//  TimeInterval+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 9/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

extension TimeInterval {

    func toPythonDateString() -> String? {
        return Formatter.pythonDate.string(from: Date(timeIntervalSinceReferenceDate: self))
    }

}
