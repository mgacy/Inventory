//
//  Router.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Alamofire

public enum NewOrderGenerationMethod: String {
    case count
    case par
    case sales
}

public enum Router: URLRequestConvertible {
    // Authentication
    case forgotPassword(email: String)
    case login(email: String, password: String)
    case logout
    case signUp(firstName: String, lastName: String, email: String, password: String)
    // General
    case getItems(storeID: Int)
    case getLocations(storeID: Int)
    case getUnits
    case getVendors(storeID: Int)
    // Inventory
    case getNewInventory(isActive: Bool, typeID: Int, storeID: Int)
    case getInventories(storeID: Int)
    case getInventory(remoteID: Int)
    case postInventory([String: Any])
    // Invoice
    case getInvoiceCollections(storeID: Int)
    case getInvoiceCollection(storeID: Int, forDate: String)
    //case postInvoice([String: Any])                                                         // Deprecated
    case putInvoice(remoteID: Int, parameters: [String: Any])
    //case putInvoiceItem(remoteID: Int, parameters: [String: Any])
    // Order
    case getOrderCollections(storeID: Int)
    case getOrderCollection(storeID: Int, forDate: String)
    case postOrderCollection(storeID: Int, generationMethod: NewOrderGenerationMethod, returnUsage: Bool,
                             periodLength: Int?)
    case postOrder([String: Any])                                                           // Deprecated

    //static let baseURLString = "http://localhost:5000"
    static let baseURLString = "https:\(AppSecrets.baseURL)"
    static let apiPath = "/api/v1.0"

    var method: HTTPMethod {
        switch self {
        // Authorization
        case .forgotPassword:
            return .post
        case .login:
            return .post
        case .logout:
            return .post
        case .signUp:
            return .post
        // General
        case .getItems:
            return .get
        case .getLocations:
            return .get
        case .getUnits:
            return .get
        case .getVendors:
            return .get
        // Inventory
        case .getNewInventory:
            return .get
        case .getInventories:
            return .get
        case .getInventory:
            return .get
        case .postInventory:
            return .post
        // Invoice
        case .getInvoiceCollections:
            return .get
        case .getInvoiceCollection:
            return .get
        //case .postInvoice:
        //    return .post
        case .putInvoice:
            return .put
        //case .putInvoiceItem:
        //    return .put
        // Order
        case .getOrderCollections:
            return .get
        case .getOrderCollection:
            return .get
        case .postOrderCollection:
            return .post
        case .postOrder:
            return .post
        }
    }

    var path: String {
        switch self {
        // Authentication
        case .forgotPassword:
            return "/auth/lost_password"
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .signUp:
            return "/signup"
        // General
        case .getItems:
            return "items"
        case .getLocations:
            return "inventory_locations"
        case .getUnits:
            return "units"
        case .getVendors:
            return "vendors"
        // Inventory
        case .getNewInventory:
            return "\(Router.apiPath)/new_inventory"
        case .getInventories:
            return "\(Router.apiPath)/inventories"
        case .getInventory(let remoteID):
            return "\(Router.apiPath)/inventories/\(remoteID)"
        case .postInventory:
            return "\(Router.apiPath)/inventories"
        // Invoice
        case .getInvoiceCollections:
            return "\(Router.apiPath)/invoice_collections"
        case .getInvoiceCollection:
            return "\(Router.apiPath)/invoice_collections"
        //case .postInvoice:
        //    return "\(Router.apiPath)/invoices"
        case .putInvoice(let remoteID, _):
            return "\(Router.apiPath)/invoices/\(remoteID)"
        //case .putInvoiceItem(let remoteID, _):
        //    return "\(Router.apiPath)/invoice_items/\(remoteID)"
        // Order
        case .getOrderCollections:
            return "\(Router.apiPath)/order_collections"
        case .getOrderCollection:
            return "\(Router.apiPath)/order_collections"
        case .postOrderCollection:
            return "\(Router.apiPath)/order_collections"
        case .postOrder:
            return "\(Router.apiPath)/orders"
        }
    }

    var parameters: Parameters {
        switch self {
        // Authentication
        case .forgotPassword(let email):
            return ["email": email]
        case .login(let email, let password):
            return ["email": email, "password": password]
        //case .logout:
        case .signUp(let firstName, let lastName, let email, let password):
            return ["first_name": firstName, "last_name": lastName, "email": email, "password": password]
        // General
        case .getItems(let storeID):
            return ["store_id": storeID]
        case .getLocations(let storeID):
            return ["store_id": storeID]
        // case .getUnits:
        // case .getVendors(let storeID):
        // Inventory
        case .getNewInventory(let isActive, _, let storeID):    // Note that we are ignoring `typeID`
            return ["active": isActive, "store_id": storeID]
        case .getInventories(let storeID):
            return ["store_id": storeID]
        case .postInventory(let parameters):
            return parameters
        // Invoice
        case .getInvoiceCollections(let storeID):
            return ["store_id": storeID]
        case .getInvoiceCollection(let storeID, let forDate):
            return ["store_id": storeID, "date": forDate]
        //case .postInvoice(let parameters):
        case .putInvoice(_, let parameters):
            return parameters
        //case .putInvoiceItem(_, let parameters):
        // Order
        case .getOrderCollections(let storeID):
            return ["store_id": storeID]
        case .getOrderCollection(let storeID, let forDate):
            return ["store_id": storeID, "date": forDate]
        case .postOrderCollection(let storeID, let generationMethod, let returnUsage, let periodLength):
            return ["store_id": storeID, "generation_method": generationMethod.rawValue, "return_usage": returnUsage,
                    "period_length": periodLength ?? 28]
        case .postOrder(let parameters):
            return parameters
        default:
            return [:]
        }
    }

    // MARK: URLRequestConvertible

    public func asURLRequest() throws -> URLRequest {
        let url = try Router.baseURLString.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        /*
        switch self {
        case .logout:
            _ = true
        case .getUnits:
            _ = true
        case .getVendors:
            _ = true
        default:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        }
         */

        switch self {
        // Authentication
        case .forgotPassword:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        case .login:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        // case .logout:
        case .signUp:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        // General
        case .getItems:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .getUnits:
        // case .getVendors:

        // Inventory
        case .getNewInventory:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .getInventories:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .postInventory:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)

        // Invoice
        case .getInvoiceCollections:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .getInvoiceCollection:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        //case .postInvoice:
        //    urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        case .putInvoice:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        //case .putInvoiceItem:
        //    urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)

        // Order
        case .getOrderCollections:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .getOrderCollection:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .postOrderCollection:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        case .postOrder:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        default:
            break
        }

        return urlRequest
    }

}
