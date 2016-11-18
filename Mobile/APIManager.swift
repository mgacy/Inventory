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
        authHandler = AuthorizationHandler.sharedInstance
        //authHandler = AuthorizationHandler()
        
        sessionManager = Alamofire.SessionManager.default
        sessionManager.adapter = authHandler
        // sessionManager.retrier = authHandler
    }
    
    // MARK: - Authorization
    func login(completionHandler completion: @escaping (Bool) -> Void ) {
        authHandler.requestToken(completionHandler: completion)
    }
    
    // MARK: - API Calls - General
    
    func getItems(storeID: Int, completionHandler completion: @escaping (Bool, JSON?) -> Void) {
        sessionManager.request(Router.getItems(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    //print("\ngetItems - response: \(response)\n")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getItems: \(error)")
                    completion(false, nil)
                }
        }
    }
    
    func getUnits(completionHandler completion: @escaping (JSON) -> Void) {
        sessionManager.request(Router.getUnits)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetUnits - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getUnits: \(error)")
                }
        }
    }
    
    func getVendors(storeID: Int, completionHandler completion: @escaping (JSON) -> Void) {
        sessionManager.request(Router.getVendors(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetVendors - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getVendors: \(error)")
                }
        }
    }
    
    // MARK: - API Calls - Inventory
    
    func getInventories(storeID: Int, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.listInventories(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetInventories - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInventories: \(error)")
                }
        }
    }

    func getInventory(remoteID: Int, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.fetchInventory(remoteID: remoteID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("/ngetInventory - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInventory: \(error)")
                }
        }
    }
    
    func getNewInventory(isActive: Bool, typeID: Int, storeID: Int, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetNewInventory - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getNewInventory: \(error)")
                }
        }
    }
    
    func postInventory(inventory: [String: Any], completionHandler completion: @escaping (Bool) -> Void) {
        sessionManager.request(Router.postInventory(inventory))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    //let json = JSON(value)
                    //completion(true, json)
                    completion(true)
                case .failure(let error):
                    print("Failure: \(error)")
                    //let json = JSON(error)
                    //completion(false, json)
                    completion(false)
                }
        }
    }
    
    // MARK: - API Calls - Invoice
    
    func getListOfInvoiceCollections(storeID: Int, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.listInvoices(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("\ngetListOfInvoiceCollections - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getListOfInvoiceCollections: \(error)")
                }
        }
    }
    
    func getInvoiceCollection(storeID: Int, invoiceDate: String, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.fetchInvoice(storeID: storeID, invoiceDate: invoiceDate))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetInvoiceCollection - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getInvoiceCollection: \(error)")
                }
        }
    }
    
    func getNewInvoiceCollection(storeID: Int, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.getNewInvoice(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetNewInvoiceCollection - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getNewInvoiceCollection: \(error)")
                }
        }
    }
    
    func postInvoice(invoice: [String: Any], completionHandler completion: @escaping (Bool, JSON) -> Void) {
        sessionManager.request(Router.postInvoice(invoice))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    print("Failure: \(error)")
                    let json = JSON(error)
                    completion(false, json)
                }
        }
    }
    
    // MARK: - API Calls - Order
    
    func getListOfOrderCollections(storeID: Int, completionHandler completion: @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.listOrders(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetListOfOrderCollections - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getListOfOrderCollections: \(error)")
                }
        }
    }
    
    func getOrderCollection(storeID: Int, orderDate: String, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.fetchOrder(storeID: storeID, orderDate: orderDate))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetOrderCollection - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getOrderCollection: \(error)")
                }
        }
    }
    
    func getNewOrderCollection(storeID: Int, typeID: Int, returnUsage: Bool, periodLength: Int?, completionHandler completion:
        @escaping (JSON) -> Void)
    {
        sessionManager.request(Router.getNewOrder(storeID: storeID, typeID: typeID,
                                                  returnUsage: returnUsage, periodLength: periodLength))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\ngetNewOrderCollection - response: \(response)\n")
                    let json = JSON(value)
                    completion(json)
                case .failure(let error):
                    // TODO - handle error somewhere
                    debugPrint("\nERROR - getNewOrderCollection: \(error)")
                }
        }
    }
    
    func postOrder(order: [String: Any], completionHandler completion: @escaping (Bool, JSON) -> Void) {
        sessionManager.request(Router.postOrder(order))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    print("Failure: \(error)")
                    let json = JSON(error)
                    completion(false, json)
                }
        }
    }
}
