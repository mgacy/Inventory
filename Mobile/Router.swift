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
    case getNewInventory(isActive: Bool, typeID: Int, storeID: Int)
    case listInventories(storeID: Int)
    case fetchInventory(remoteID: Int)
    case postInventory([String: AnyObject])
    
    //static let baseURLString = "http://127.0.0.1:5000"
    static let baseURLString = "http:mgacy.pythonanywhere.com"
    static let apiPath = "/api/v1.0"
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .getNewInventory:
            return .get
        case .listInventories:
            return .get
        case .fetchInventory:
            return .get
        case .postInventory:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .getNewInventory:
            return "\(Router.apiPath)/new_inventory"
        case .listInventories:
            return "\(Router.apiPath)/inventories"
        case .fetchInventory(let remoteID):
            return "\(Router.apiPath)/inventories/\(remoteID)"
        case .postInventory:
            return "/inventories"
        }
    }
    
    var parameters: Parameters {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .getNewInventory(let isActive, let typeID, let storeID):
            return ["active": isActive, "inventory_type_id": typeID, "store_id": storeID]
        // case .listInventories:
        // case .fetchInventory:
        // case .postInventory:
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
        case .getNewInventory:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        // case .listInventories:
        // case .fetchInventory(let remoteID):
        // case .postInventory(let parameters):
        default:
            break
        }
        
        return urlRequest
    }
    
}
