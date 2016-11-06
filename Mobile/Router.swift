//
//  NetworkingStack.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public enum Router: URLRequestConvertible {
    case login(email: String, password: String)
    // Inventory
    case getNewInventory(isActive: Bool, typeID: Int, storeID: Int)
    case listInventories(storeID: Int)
    case fetchInventory(remoteID: Int)
    case postInventory([String: Any])
    // Invoice
    case getNewInvoice()
    case listInvoices(storeID: Int)
    case fetchInvoice(storeID: Int)
    case postInvoice([String: Any])
    // Order
    case getNewOrder(storeID: Int, typeID: Int, returnUsage: Bool, periodLength: Int?)
    case listOrders(storeID: Int)
    case fetchOrder(storeID: Int, orderDate: String)
    case postOrder([String: Any])
    
    //static let baseURLString = "http://127.0.0.1:5000"
    static let baseURLString = "http:mgacy.pythonanywhere.com"
    static let apiPath = "/api/v1.0"
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        // Inventory
        case .getNewInventory:
            return .get
        case .listInventories:
            return .get
        case .fetchInventory:
            return .get
        case .postInventory:
            return .post
        // Invoice
         case .getNewInvoice:
             return .get
         case .listInvoices:
             return .get
         case .fetchInvoice:
             return .get
         case .postInvoice:
             return .post
        // Order
        case .getNewOrder:
            return .get
        case .listOrders:
            return .get
        case .fetchOrder:
            return .get
        case .postOrder:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        // Inventory
        case .getNewInventory:
            return "\(Router.apiPath)/new_inventory"
        case .listInventories:
            return "\(Router.apiPath)/inventories"
        case .fetchInventory(let remoteID):
            return "\(Router.apiPath)/inventories/\(remoteID)"
        case .postInventory:
            return "\(Router.apiPath)/inventories"
        // Invoice
         case .getNewInvoice:
             return "\(Router.apiPath)/new_invoice"
         case .listInvoices:
             return "\(Router.apiPath)/invoices"
         case .fetchInvoice:
             return "\(Router.apiPath)/invoices"
         case .postInvoice:
             return "\(Router.apiPath)/invoices"
        // Order
        case .getNewOrder:
            return "\(Router.apiPath)/new_order"
        case .listOrders:
            return "\(Router.apiPath)/orders"
        case .fetchOrder:
            return "\(Router.apiPath)/orders"
        case .postOrder:
            return "\(Router.apiPath)/orders"
        }
    }
    
    var parameters: Parameters {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        // Inventory
        case .getNewInventory(let isActive, let typeID, let storeID):
            return ["active": isActive, "inventory_type_id": typeID, "store_id": storeID]
        // case .listInventories(let typeID):
        // case .fetchInventory:
        case .postInventory(let parameters):
            return parameters
        // Invoice
        // case .getNewInvoice:
        // case .listInvoices:
        // case .fetchInvoice:
        case .postInvoice(let parameters):
            return parameters
        // Order
        case .getNewOrder(let storeID, let typeID, let returnUsage, let periodLength):
            return ["store_id": storeID, "inventory_type": typeID,
                    "return_usage": returnUsage, "period_length": periodLength ?? 28]
        case .listOrders(let storeID):
            return ["store_id": storeID]
        case .fetchOrder(let storeID, let orderDate):
            return ["store_id": storeID, "order_date": orderDate]
        case .postOrder(let parameters):
            return parameters
        default:
            return [:]
        }
    }
    
    // MARK: URLRequestConvertible
    
    public func asURLRequest() throws -> URLRequest {
        // TODO: can I simply add apiURL here?
        //let urlString = Router.baseURLString + Router.apiURL
        //let url = try urlString.asURL()
        
        let url = try Router.baseURLString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        
        switch self {
        case .login:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            
        // Inventory
        case .getNewInventory:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .listInventories:
        // case .fetchInventory(let remoteID):
        case .postInventory:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            
        // Invoice
        // case .getNewInvoice:
        //     urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .listInvoices:
        // case .fetchInvoice:
        // case .postInvoice:
        //     urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        
        // Order
        case .getNewOrder:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .listOrders:
        case .fetchOrder:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .postOrder:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        default:
            break
        }
        
        return urlRequest
    }
    
}
