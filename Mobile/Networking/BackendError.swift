//
//  BackendError.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/15/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import Foundation

// NOTE: this is taken from Alamofire README
// NOTE: See "iOS Apps with REST APIs" Ch. 3.4 for an explanation of what is going on here

public enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case authentication(error: Error)
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
    case myError(error: String)
}

extension BackendError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network Error: \(error.localizedDescription)"
        case .authentication(let error):
            return "Authentication Error: \(error.localizedDescription)"
        case .dataSerialization(let error):
            return "Data Serialization Error: \(error.localizedDescription)"
        case .jsonSerialization(let error):
            return "JSON Serialization Error: \(error.localizedDescription)"
        case .xmlSerialization(let error):
            return "XML Serialization Error: \(error.localizedDescription)"
        case .objectSerialization(let reason):
            return "Object Serialization Error: \(reason)"
        case .myError(let message):
            return message
        }
    }
}
