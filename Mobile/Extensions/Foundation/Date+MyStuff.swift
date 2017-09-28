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
        self.dateFormat = "yyyy-MM-dd"
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

extension Date {

    static let basicDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let altDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    func stringFromDate() -> String? {
        return Date.basicDate.string(from: self)
    }

    func altStringFromDate() -> String? {
        return Date.altDate.string(from: self)
    }

}
