//
//  Router2.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/3/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public enum Router2: URLRequestConvertible {
    //case getItems(active: Bool?, categoryID: Int?, storeID: Int)
    case getItems(storeID: Int)
    case getUnits
    case getVendors

    static let baseURLString = "http://127.0.0.1:5000"
    //static let baseURLString = "http:mgacy.pythonanywhere.com"
    // static let apiPath = "/api/v1.0"

    var method: HTTPMethod {
        switch self {
        case .getItems:
            return .get
        case .getUnits:
            return .get
        case .getVendors:
            return .get
        }
    }

    var path: String {
        switch self {
        case .getItems:
            return "items"
        case .getUnits:
            return "units"
        case .getVendors:
            return "vendors"
        }
    }

    var parameters: Parameters {
        switch self {
        //case .getItems(let active, let categoryID, let storeID):
        case .getItems(let storeID):
            return ["storeID": storeID]
        // case .getUnits:
        // case .getVendors:
        default:
            return [:]
        }
    }

    // MARK: URLRequestConvertible

    public func asURLRequest() throws -> URLRequest {
        let url = try Router2.baseURLString.asURL()

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        switch self {
        case .getItems:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .getUnits:
        // case .getVendors:
        default:
            break
        }

        return urlRequest
    }

}
