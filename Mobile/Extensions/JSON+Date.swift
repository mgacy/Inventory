//
//  JSON+Date.swift
//  Mobile
//
//  Created by Mathew Gacy on 7/20/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

//import Foundation
import SwiftyJSON

extension JSON {

    // https://stackoverflow.com/a/36805702/4472195
    // https://stackoverflow.com/a/42047429/4472195
    private static let jsonDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        return dateFormatter
    }()

    public var date: Date? {
        if let str = self.string {
            return JSON.jsonDateFormatter.date(from: str)
        }
        return nil
    }

}
