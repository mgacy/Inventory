//
//  APIManager.swift
//  Playground
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class APIManager {
    
    // MARK: Properties
    
    static let sharedInstance = APIManager()
    private let authHandler: AuthorizationHandler
    private let sessionManager: SessionManager
    
    // MARK: Lifecycle
    
    init() {    
        authHandler = AuthorizationHandler()

        sessionManager = Alamofire.SessionManager.default
        sessionManager.adapter = authHandler
        // sessionManager.retrier = authHandler
    }
    
    // MARK: Authorization
    func login(completionHandler: @escaping (Bool) -> Void ) {
        authHandler.requestToken(completionHandler: completionHandler)
    }
    
    // MARK: API Calls
    
    func getInventories(storeID: Int, completionHandler:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.listInventories(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetInventories - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO: handle error somewhere
                    debugPrint("\nERROR - getInventories: \(error)")
                }
        }
    }

    func getInventory(remoteID: Int, completionHandler:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.fetchInventory(remoteID: remoteID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("/ngetInventory - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO: handle error somewhere
                    debugPrint("\nERROR - getInventory: \(error)")
                }
        }
    }
    
    func getNewInventory(isActive: Bool, typeID: Int, storeID: Int, completionHandler:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetNewInventory - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO: handle error somewhere
                    debugPrint("\nERROR - getNewInventory: \(error)")
                }
        }
    }
}
