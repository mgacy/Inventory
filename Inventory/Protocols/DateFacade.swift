//
//  DateFacade.swift
//  Mobile
//
//  Created by Mathew Gacy on 9/30/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import CoreData

protocol DateFacade: class, NSFetchRequestResult {
    var dateTimeInterval: TimeInterval { get set }
}

extension DateFacade {
    public var date: Date {
        get {
            //return Date(timeIntervalSince1970: dateTimeInterval)
            return Date(timeIntervalSinceReferenceDate: dateTimeInterval)
        }
        set {
            //dateTimeInterval = newValue.timeIntervalSince1970
            dateTimeInterval = newValue.timeIntervalSinceReferenceDate
        }
    }
}
