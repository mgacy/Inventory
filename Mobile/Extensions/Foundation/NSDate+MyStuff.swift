//
//  NSDate+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/28332946/nsdateformatter-stringfromdatensdate-returns-empty-string
extension NSDate {

    func dateFromString(date: String, format: String = "yyyy-MM-dd") -> NSDate? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = format

        return formatter.date(from: date) as NSDate?
    }

    func stringFromDate(format: String = "yyyy-MM-dd") -> String? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = format

        return formatter.string(from: self as Date)
    }

}

// Alternatively, see:
// https://stackoverflow.com/questions/36805662/use-swiftyjson-to-deserialize-nsdate
// https://grokswift.com/nsdate-webservices/
