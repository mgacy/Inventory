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

    func getItems(storeID: Int, completion: @escaping (JSON?, Error?) -> Void) {
        sessionManager.request(Router.getItems(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getUnits(completion: @escaping (JSON?, Error?) -> Void) {
        sessionManager.request(Router.getUnits)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getVendors(storeID: Int, completion: @escaping (JSON?, Error?) -> Void) {
        sessionManager.request(Router.getVendors(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    // MARK: - API Calls - Inventory

    func getListOfInventories(storeID: Int, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.listInventories(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getInventory(remoteID: Int, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.fetchInventory(remoteID: remoteID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getNewInventory(isActive: Bool, typeID: Int, storeID: Int, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func postInventory(inventory: [String: Any], completion: @escaping (JSON?, Error?) -> Void) {
        sessionManager.request(Router.postInventory(inventory))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("Success: \(value)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    let json = JSON(error)
                    completion(json, error)
                }
        }
    }

    // MARK: - API Calls - Invoice

    func getListOfInvoiceCollections(storeID: Int, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.listInvoices(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getInvoiceCollection(storeID: Int, invoiceDate: String, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.fetchInvoice(storeID: storeID, invoiceDate: invoiceDate))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getNewInvoiceCollection(storeID: Int, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.getNewInvoice(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func postInvoice(invoice: [String: Any], completion: @escaping (Bool, JSON) -> Void) {
        sessionManager.request(Router.postInvoice(invoice))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    let json = JSON(error)
                    completion(false, json)
                }
        }
    }

    // MARK: - API Calls - Order

    func getListOfOrderCollections(storeID: Int, completion: @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.listOrders(storeID: storeID))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getOrderCollection(storeID: Int, orderDate: String, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.fetchOrder(storeID: storeID, orderDate: orderDate))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getNewOrderCollection(storeID: Int, typeID: Int, returnUsage: Bool, periodLength: Int?, completion:
        @escaping (JSON?, Error?) -> Void)
    {
        sessionManager.request(Router.getNewOrder(storeID: storeID, typeID: typeID,
                                                  returnUsage: returnUsage, periodLength: periodLength))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // print("\n\(#function) - response: \(response)\n")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func postOrder(order: [String: Any], completion: @escaping (Bool, JSON) -> Void) {
        sessionManager.request(Router.postOrder(order))
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("Success: \(value)")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    let json = JSON(error)
                    completion(false, json)
                }
        }
    }
}
