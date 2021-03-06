//
//  NSDate+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/6/17.
//

import Foundation

/*
 * If you cache date formatters (or any other objects that depend on the user’s current locale), you should subscribe 
 * to the `NSCurrentLocaleDidChangeNotification` notification and update your cached objects when the current locale
 * changes. [Source](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html#//apple_ref/doc/uid/TP40002369-SW10)
 */

extension Formatter {

    //static let display: DateFormatter = {}()

    // Inspired by: https://stackoverflow.com/a/43658213/4472195
    // See also:    https://stackoverflow.com/a/42370648/4472195
    static let pythonDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        //formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

}

// MARK: - NSDate
/*
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
*/
// MARK: - String

extension String {

    // TODO: add method to convert string to TimeInterval?
    //func toTimeInterval() -> TimeInterval? {}

    func toBasicDate() -> Date? {
        return Formatter.pythonDate.date(from: self)
    }

}
