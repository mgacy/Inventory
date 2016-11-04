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
    
    // MARK: - Authorization
    func login(completionHandler: @escaping (Bool) -> Void ) {
        authHandler.requestToken(completionHandler: completionHandler)
    }
    
    // MARK: - API Calls - Inventory
    
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
                    // TODO - handle error somewhere
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
                    // TODO - handle error somewhere
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
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getNewInventory: \(error)")
                }
        }
    }
    
    func postInventory(inventory: [String: Any], completionHandler: @escaping (Bool) -> Void) {
        sessionManager.request(Router.postInventory(inventory))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    completionHandler(true)
                case .failure(let error):
                    print("Failure: \(error)")
                    completionHandler(false)
                }
        }
    }
    
    // MARK: - API Calls - Invoice
    
    func getListOfInvoices(storeID: Int, typeID: Int, orderDate: String, completionHandler:
        @escaping (JSON) -> Void)
    {}
    
    func getInvoice(remoteID: Int, completionHandler:
        @escaping (JSON) -> Void)
    {}
    
    func getNewInvoice(storeID: Int, typeID: Int, returnUsage: Bool, periodLength: Int?, completionHandler:
        @escaping (JSON) -> Void)
    {}
    
    func postInvoice(invoice: [String: Any], completionHandler: @escaping (Bool) -> Void) {}
    
    // MARK: - API Calls - Order
    
    func getListOfOrderCollections(storeID: Int, completionHandler: @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.listOrders(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetListOfOrders - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getListOfOrders: \(error)")
                }
        }
    }
    
    func getOrderCollection(storeID: Int, orderDate: String, completionHandler:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.fetchOrder(storeID: storeID, orderDate: orderDate))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetOrder - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getOrder: \(error)")
                }
        }
    }
    
    func getNewOrderCollection(storeID: Int, typeID: Int, returnUsage: Bool, periodLength: Int?, completionHandler:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.getNewOrder(storeID: storeID, typeID: typeID,
                                                  returnUsage: returnUsage, periodLength: periodLength))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetNewOrder - response: \(response)\n")
                    let json = JSON(value)
                    completionHandler(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getNewOrder: \(error)")
                }
        }
    }
    
    func postOrder(order: [String: Any], completionHandler: @escaping (Bool) -> Void) {
        sessionManager.request(Router.postOrder(order))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    completionHandler(true)
                case .failure(let error):
                    print("Failure: \(error)")
                    completionHandler(false)
                }
        }
    }
}
