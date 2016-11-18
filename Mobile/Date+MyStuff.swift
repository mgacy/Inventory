//
//  Date+MyStuff.swift
//  Mobile
//
//  Source: 
//  http://stackoverflow.com/users/2303865/leo-dabus
//  http://stackoverflow.com/questions/28332946/nsdateformatter-stringfromdatensdate-returns-empty-string
//
//  Created by Mathew Gacy on 11/16/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation

extension DateFormatter {
    convenience init(dateStyle: DateFormatter.Style) {
        self.init()
        self.dateStyle = dateStyle
    }
}

extension Date {
    struct Formatter {
        static let shortDate = DateFormatter(dateStyle: .short)
    }
    
    var shortDate: String {
        return Formatter.shortDate.string(from: self)
    }
}
