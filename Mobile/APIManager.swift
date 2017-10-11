//
//  APIManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON
import RxCocoa
import RxSwift

/*
NOTE - BackendError already declared in AlamofireRequest+JSONSerializable.swift

enum MyResult {
    case success(JSON?)
    case failure(BackendError)
}
*/

class APIManager {

    // MARK: Properties

    static let sharedInstance = APIManager()
    private let sessionManager: SessionManager
    private let decoder: JSONDecoder

    typealias CompletionHandlerType = (JSON?, Error?) -> Void

    // MARK: Lifecycle

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8 // seconds
        configuration.timeoutIntervalForResource = 8
        sessionManager = Alamofire.SessionManager(configuration: configuration)
        decoder = JSONDecoder()
    }

    func configSession(_ authHandler: AuthenticationHandler?) {
        sessionManager.adapter = authHandler
        sessionManager.retrier = authHandler
    }

    // MARK: - Authentication

    //func logout() -> Observable<DataResonse> {}

    func logout(completion: @escaping (Bool) -> Void) {
        sessionManager.request(Router.logout)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    log.verbose("\(#function) - response: \(response)")
                    completion(true)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(false)
                }
        }
    }

    // MARK: Private
    /// TODO: pass `sessionManager: SessionManager, decoder: JSONDecoder`?

    private func postOne<M: Codable>(_ endpoint: Router) -> Observable<DataResponse<M>> {
        /// TODO: include where validating endpoint.method == HTTPMethod.post
        return Observable<DataResponse<M>>.create { observer in
            let request = self.sessionManager.request(endpoint)
            request
                .validate()
                .responseDecodableObject(decoder: self.decoder) { (response: DataResponse<M>) in
                    observer.onNext(response)
                    observer.onCompleted()
            }
            return Disposables.create {
                request.cancel()
            }
        }
    }

    private func requestOne<M: Codable>(_ endpoint: Router) -> Observable<DataResponse<M>> {
        return Observable<DataResponse<M>>.create { observer in
            //let decoder = JSONDecoder()
            let request = self.sessionManager.request(endpoint)
            request
                .validate()
                .responseDecodableObject(decoder: self.decoder) { (response: DataResponse<M>) in
                    observer.onNext(response)
                    observer.onCompleted()
            }
            return Disposables.create {
                request.cancel()
            }
        }
    }

    private func requestList<M: Codable>(_ route: Router) -> Observable<DataResponse<[M]>> {
        return Observable<DataResponse<[M]>>.create { observer in
            //let decoder = JSONDecoder()
            let request = self.sessionManager.request(route)
            request
                .validate()
                .responseDecodableObject(decoder: self.decoder) { (response: DataResponse<[M]>) in
                    observer.onNext(response)
                    observer.onCompleted()
            }
            return Disposables.create {
                request.cancel()
            }
        }
    }

}

// MARK: - General
extension APIManager {

    func getItems(storeID: Int) -> Observable<DataResponse<[RemoteItem]>> {
        return requestList(Router.getItems(storeID: storeID))
    }
    /*
     func getItemCategories(storeID: Int) -> Observable<DataResponse<[RemoteItemCategory]>> {
     return requestList(Router.getItemCategories(storeID: storeID))
     }
     */
    func getVendors(storeID: Int) -> Observable<DataResponse<[RemoteVendor]>> {
        return requestList(Router.getVendors(storeID: storeID))
    }

}

// MARK: - Inventory - NEW
extension APIManager {

    func getInventories(storeID: Int) -> Observable<DataResponse<[RemoteInventory]>> {
        return requestList(Router.listInventories(storeID: storeID))
    }

    func getInventory(remoteID: Int) -> Observable<DataResponse<RemoteInventory>> {
        /// TODO: just accept `Inventory` so DataManager doesn't need to know anything about endpoint params?
        return requestOne(Router.fetchInventory(remoteID: remoteID))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    func postInventory(storeID: Int) -> Observable<DataResponse<RemoteInventory>> {
        /// TODO: update to actually use POST
        //return postOne(Router.postInventory)
        let isActive = true
        let typeID = 1
        return requestOne(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
    }

    // func putInventory(_ inventory: RemoteInventory) -> Observable<DataResponse<RemoteInventory>> {}

}

// MARK: - Inventory - OLD
extension APIManager {

    func getListOfInventories(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.listInventories(storeID: storeID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getInventory(remoteID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.fetchInventory(remoteID: remoteID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getNewInventory(isActive: Bool, typeID: Int, storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
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
                    log.verbose("\(#function) success : \(value)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    let json = JSON(error)
                    completion(json, error)
                }
        }
    }

}

// MARK: - Invoice - NEW
extension APIManager {

    func getInvoiceCollections(storeID: Int) -> Observable<DataResponse<[RemoteInvoiceCollection]>> {
        return requestList(Router.getInvoiceCollections(storeID: storeID))
    }

    func getInvoiceCollection(storeID: Int, invoiceDate: String) -> Observable<DataResponse<RemoteInvoiceCollection>> {
        return requestOne(Router.getInvoiceCollection(storeID: storeID, forDate: invoiceDate))
    }

}

// MARK: - Invoice
extension APIManager {

    func getListOfInvoiceCollections(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.listInvoices(storeID: storeID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }
    /*
    func getInvoiceCollection(storeID: Int, invoiceDate: String, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.fetchInvoice(storeID: storeID, invoiceDate: invoiceDate))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }
     */
    func getNewInvoiceCollection(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.getNewInvoice(storeID: storeID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
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
                    log.verbose("\(#function) success : \(value)")
                    let json = JSON(value)
                    completion(true, json)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    let json = JSON(error)
                    completion(false, json)
                }
        }
    }

    func putInvoice(remoteID: Int, invoice: [String: Any], completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.putInvoice(remoteID: remoteID, parameters: invoice))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    log.verbose("\(#function) success : \(value)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    //let json = JSON(error)
                    completion(nil, error)
                }
        }
    }

    func putInvoiceItem(remoteID: Int, item: [String: Any], completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.putInvoiceItem(remoteID: remoteID, parameters: item))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    log.verbose("\(#function) success : \(value)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    //let json = JSON(error)
                    completion(nil, error)
                }
        }
    }

}

// MARK: - Order - NEW
extension APIManager {

    func getOrderCollections(storeID: Int) -> Observable<DataResponse<[RemoteOrderCollection]>> {
        return requestList(Router.getOrderCollections(storeID: storeID))
    }

    func getOrderCollection(storeID: Int, orderDate: String) -> Observable<DataResponse<RemoteOrderCollection>> {
        return requestOne(Router.getOrderCollection(storeID: storeID, forDate: orderDate))
    }

    func postOrderCollection(storeID: Int, generationMethod: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?) -> Observable<DataResponse<RemoteOrderCollection>> {

        var parameters = [String: Any]()
        parameters["store_id"] = storeID
        parameters["generation_method"] = generationMethod.rawValue
        //parameters["return_usage"] = returnUsage
        parameters["period_length"] = periodLength ?? 28

        return postOne(Router.postOrderCollection(parameters))
        //return postOne(Router.postOrderCollection(storeID: storeID, generationMethod: generationMethod,
        //                                          returnUsage: returnUsage, periodLength: periodLength))
    }

}

// MARK: - Order
extension APIManager {

    func getListOfOrderCollections(storeID: Int, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.listOrders(storeID: storeID))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getOrderCollection(storeID: Int, orderDate: String, completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.fetchOrder(storeID: storeID, orderDate: orderDate))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func getNewOrderCollection(storeID: Int, generateFrom method: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?, completion:
        @escaping CompletionHandlerType) {
        sessionManager.request(Router.getNewOrder(storeID: storeID, generationMethod: method,
                                                  returnUsage: returnUsage, periodLength: periodLength))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

    func postOrder(order: [String: Any], completion: @escaping CompletionHandlerType) {
        sessionManager.request(Router.postOrder(order))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    log.verbose("\(#function) success : \(value)")
                    let json = JSON(value)
                    completion(json, nil)
                case .failure(let error):
                    log.warning("\(#function) FAILED : \(error)")
                    completion(nil, error)
                }
        }
    }

}
