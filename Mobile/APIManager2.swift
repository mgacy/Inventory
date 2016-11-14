//
//  APIManager2.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/3/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class APIManager2 {

    // MARK: Properties

    static let sharedInstance = APIManager2()
    private let authHandler: AuthorizationHandler
    private let sessionManager: SessionManager

    // MARK: Lifecycle

    init() {
        //authHandler = AuthorizationHandler()
        authHandler = AuthorizationHandler.sharedInstance

        sessionManager = Alamofire.SessionManager.default
        sessionManager.adapter = authHandler
        // sessionManager.retrier = authHandler
    }
    
    // MARK: - API Calls - Inventory

    //func getItems(active: Bool?, categoryID: Int, storeID: Int, id: Int?, completionHandler:
    func getItems(storeID: Int, completionHandler: @escaping (Bool, JSON?) -> Void) {
        sessionManager.request(Router2.getItems(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    //print("\ngetItems - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(true, json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInventories: \(error)")
                    completionHandler(false, nil)
                }
        }
    }
    
    func getUnits(completionHandler: @escaping (JSON) -> Void) {
        sessionManager.request(Router2.getUnits)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetInventories - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInventories: \(error)")
                }
        }
    }
    
    func getVendors(completionHandler: @escaping (JSON) -> Void) {
        sessionManager.request(Router2.getVendors)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetInventories - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInventories: \(error)")
                }
        }
    }
}
