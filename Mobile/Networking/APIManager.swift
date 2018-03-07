//
//  APIManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Alamofire
import CodableAlamofire
import RxCocoa
import RxSwift

// NOTE: this is taken from Alamofire README
// NOTE: See "iOS Apps with REST APIs" Ch. 3.4 for an explanation of what is going on here

public enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case authentication(error: Error)
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
    case myError(error: String)
}

class APIManager {

    // MARK: Properties

    static let sharedInstance = APIManager()
    private let sessionManager: SessionManager
    private let decoder: JSONDecoder
    private let queue = DispatchQueue.main
    //private let queue = DispatchQueue(label: "com.mgacy.response-queue", qos: .utility, attributes: [.concurrent])

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
        //decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: Public

    func configSession(_ authHandler: AuthenticationHandler?) {
        sessionManager.adapter = authHandler
        sessionManager.retrier = authHandler
    }

    func request<M: Codable>(_ endpoint: URLRequestConvertible) -> Observable<DataResponse<M>> {
        return Observable<DataResponse<M>>.create { [unowned self] observer in
            let request = self.sessionManager.request(endpoint)
            request
                .validate()
                .responseDecodableObject(queue: self.queue, decoder: self.decoder) { (response: DataResponse<M>) in
                    observer.onNext(response)
                    observer.onCompleted()
            }
            return Disposables.create {
                request.cancel()
            }
        }
    }

}

// MARK: - Authentication
extension APIManager {

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

}

// MARK: - General
extension APIManager {

    func getItems(storeID: Int) -> Observable<DataResponse<[RemoteItem]>> {
        return request(Router.getItems(storeID: storeID))
    }
    /*
    func getItemCategories(storeID: Int) -> Observable<DataResponse<[RemoteItemCategory]>> {
        return request(Router.getItemCategories(storeID: storeID))
    }
     */

    func getLocations(storeID: Int) -> Observable<DataResponse<[RemoteLocation]>> {
        return request(Router.getLocations(storeID: storeID))
    }

    func getVendors(storeID: Int) -> Observable<DataResponse<[RemoteVendor]>> {
        return request(Router.getVendors(storeID: storeID))
    }

}

// MARK: - Inventory
extension APIManager {

    func getInventories(storeID: Int) -> Observable<DataResponse<[RemoteInventory]>> {
        return request(Router.getInventories(storeID: storeID))
    }

    func getInventory(remoteID: Int) -> Observable<DataResponse<RemoteExistingInventory>> {
        /// TODO: just accept `Inventory` so DataManager doesn't need to know anything about endpoint params?
        return request(Router.getInventory(remoteID: remoteID))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    func postInventory(storeID: Int) -> Observable<DataResponse<RemoteNewInventory>> {
        /// TODO: update to actually use POST
        //return request(Router.postInventory)
        let isActive = true
        let typeID = 1
        return request(Router.getNewInventory(isActive: isActive, typeID: typeID, storeID: storeID))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    func putInventory(_ inventory: [String: Any]) -> Observable<DataResponse<RemoteExistingInventory>> {
        //let serializedInventory = inventory.serialize()
        return request(Router.postInventory(inventory))
    }

}

// MARK: - Invoice
extension APIManager {

    func getInvoiceCollections(storeID: Int) -> Observable<DataResponse<[RemoteInvoiceCollection]>> {
        return request(Router.getInvoiceCollections(storeID: storeID))
    }

    func getInvoiceCollection(storeID: Int, invoiceDate: String) -> Observable<DataResponse<RemoteInvoiceCollection>> {
        return request(Router.getInvoiceCollection(storeID: storeID, forDate: invoiceDate))
    }

    func putInvoice(remoteID: Int, invoice: [String: Any]) -> Observable<DataResponse<RemoteInvoice>> {
        return request(Router.putInvoice(remoteID: remoteID, parameters: invoice))
    }
    /*
    func postInvoice(_ invoice: [String: Any]) -> Observable<DataResponse<RemoteInvoice>> {
        return request(Router.postInvoice(invoice))
    }

    func putInvoiceItem(remoteID: Int, invoiceItem: [String:Any]) -> Observable<DataResponse<RemoteInvoiceItem>> {
        return request(Router.putInvoiceItem(remoteID: remoteID, parameters: invoiceItem))
    }
    */
}

// MARK: - Order
extension APIManager {

    func getOrderCollections(storeID: Int) -> Observable<DataResponse<[RemoteOrderCollection]>> {
        return request(Router.getOrderCollections(storeID: storeID))
    }

    func getOrderCollection(storeID: Int, orderDate: String) -> Observable<DataResponse<RemoteOrderCollection>> {
        return request(Router.getOrderCollection(storeID: storeID, forDate: orderDate))
    }

    func postOrderCollection(storeID: Int, generationMethod: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?) -> Observable<DataResponse<RemoteOrderCollection>> {
        return request(Router.postOrderCollection(storeID: storeID, generationMethod: generationMethod,
                                                     returnUsage: returnUsage, periodLength: periodLength))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    /// TODO: should remoteID be a separate argument?
    func putOrder(_ order: [String: Any]) -> Observable<DataResponse<RemoteOrder>> {
        return request(Router.postOrder(order))
    }

}
