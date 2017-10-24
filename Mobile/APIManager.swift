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

        // JSON Decoding
        decoder = JSONDecoder()
        //decoder.dateDecodingStrategy = .formatted(Date.basicDate)
        //decoder.dateDecodingStrategy = .iso8601
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

// MARK: - Inventory
extension APIManager {

    func getInventories(storeID: Int) -> Observable<DataResponse<[RemoteInventory]>> {
        return requestList(Router.getInventories(storeID: storeID))
    }

    func getInventory(remoteID: Int) -> Observable<DataResponse<RemoteExistingInventory>> {
        /// TODO: just accept `Inventory` so DataManager doesn't need to know anything about endpoint params?
        return requestOne(Router.getInventory(remoteID: remoteID))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    func postInventory(storeID: Int) -> Observable<DataResponse<RemoteNewInventory>> {
        /// TODO: update to actually use POST
        //return requestOne(Router.postInventory)
        let isActive = true
        let typeID = 1
        return requestOne(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    func putInventory(_ inventory: [String: Any]) -> Observable<DataResponse<RemoteExistingInventory>> {
        //let serializedInventory = inventory.serialize()
        return requestOne(Router.postInventory(inventory))
    }

}

// MARK: - Invoice
extension APIManager {

    func getInvoiceCollections(storeID: Int) -> Observable<DataResponse<[RemoteInvoiceCollection]>> {
        return requestList(Router.getInvoiceCollections(storeID: storeID))
    }

    func getInvoiceCollection(storeID: Int, invoiceDate: String) -> Observable<DataResponse<RemoteInvoiceCollection>> {
        return requestOne(Router.getInvoiceCollection(storeID: storeID, forDate: invoiceDate))
    }

    func putInvoice(remoteID: Int, invoice: [String: Any]) -> Observable<DataResponse<RemoteInvoice>> {
        return requestOne(Router.putInvoice(remoteID: remoteID, parameters: invoice))
    }

}
/*
// MARK: - Invoice - OLD
extension APIManager {

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
*/
// MARK: - Order
extension APIManager {

    func getOrderCollections(storeID: Int) -> Observable<DataResponse<[RemoteOrderCollection]>> {
        return requestList(Router.getOrderCollections(storeID: storeID))
    }

    func getOrderCollection(storeID: Int, orderDate: String) -> Observable<DataResponse<RemoteOrderCollection>> {
        return requestOne(Router.getOrderCollection(storeID: storeID, forDate: orderDate))
    }

    func postOrderCollection(storeID: Int, generationMethod: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?) -> Observable<DataResponse<RemoteOrderCollection>> {

        /// TODO: relocate / rework
        var parameters = [String: Any]()
        parameters["store_id"] = storeID
        parameters["generation_method"] = generationMethod.rawValue
        //parameters["return_usage"] = returnUsage
        parameters["period_length"] = periodLength ?? 28

        return requestOne(Router.postOrderCollection(parameters))
        //return requestOne(Router.postOrderCollection(storeID: storeID, generationMethod: generationMethod,
        //                                          returnUsage: returnUsage, periodLength: periodLength))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    /// TODO: should remoteID be a separate argument?
    func putOrder(_ order: [String: Any]) -> Observable<DataResponse<RemoteOrder>> {
        return requestOne(Router.postOrder(order))
    }

}
/*
// MARK: - Order - OLD
extension APIManager {

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

}
*/
