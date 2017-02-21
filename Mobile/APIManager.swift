//
//  APIManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/*
enum BackendError: Error {
    case authentication(error: Error)
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
}

enum MyResult {
    case success(JSON?)
    case failure(BackendError)
}
*/

class APIManager {

    // MARK: Properties

    static let sharedInstance = APIManager()
    // private let authHandler: AuthenticationHandler
    let authHandler: AuthenticationHandler
    private let sessionManager: SessionManager

    typealias CompletionHandlerType = (JSON?, Error?) -> Void

    // MARK: Lifecycle

    init() {
        authHandler = AuthenticationHandler()

        sessionManager = Alamofire.SessionManager.default
        sessionManager.adapter = authHandler
        sessionManager.retrier = authHandler
    }

    // MARK: - Authentication
    func forgotPassword(email: String, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.forgotPassword(email: email))
            .validate()
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

    func login(completion: @escaping (Bool) -> Void) {
        authHandler.login(completion: completion)
    }

    func logout(completion: @escaping (Bool) -> Void) {
        sessionManager.request(Router.logout)
            .validate()
            .responseJSON { response in
                switch response.result {
                //case .success(let value):
                case .success:
                    print("\n\(#function) - response: \(response)\n")
                    // TODO - handle authHandler
                    //let json = JSON(value)
                    //completion(json, nil)
                    completion(true)
                case .failure(let error):
                    debugPrint("\(#function) FAILED : \(error)")
                    //completion(nil, error)
                    completion(false)
                }
        }
    }

    func signUp(email: String, password: String, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.signUp(email: email, password: password))
            .validate()
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

    // MARK: - API Calls - General

    func getItems(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.getItems(storeID: storeID))
            .validate()
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

    func getUnits(completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.getUnits)
            .validate()
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

    func getVendors(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.getVendors(storeID: storeID))
            .validate()
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

    func getListOfInventories(storeID: Int, completion: @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.listInventories(storeID: storeID))
            .validate()
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

    func getInventory(remoteID: Int, completion: @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.fetchInventory(remoteID: remoteID))
            .validate()
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
        @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
            .validate()
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

    func postInventory(inventory: [String: Any], completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.postInventory(inventory))
            .validate()
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

    func getListOfInvoiceCollections(storeID: Int, completion: @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.listInvoices(storeID: storeID))
            .validate()
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
        @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.fetchInvoice(storeID: storeID, invoiceDate: invoiceDate))
            .validate()
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
        @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.getNewInvoice(storeID: storeID))
            .validate()
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
            .validate()
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

    func getListOfOrderCollections(storeID: Int, completion: @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.listOrders(storeID: storeID))
            .validate()
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
        @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.fetchOrder(storeID: storeID, orderDate: orderDate))
            .validate()
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
        @escaping CompletionHandlerType)
    {
        sessionManager.request(Router.getNewOrder(storeID: storeID, typeID: typeID,
                                                  returnUsage: returnUsage, periodLength: periodLength))
            .validate()
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
            .validate()
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
