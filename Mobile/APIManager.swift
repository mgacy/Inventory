//
//  APIManager.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/6/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Alamofire
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
    /*
    func postInvoice(_ invoice: [String: Any]) -> Observable<DataResponse<RemoteInvoice>> {
        return requestOne(Router.postInvoice(invoice))
    }

    func putInvoiceItem(remoteID: Int, invoiceItem: [String:Any]) -> Observable<DataResponse<RemoteInvoiceItem>> {
        return requestOne(Router.putInvoiceItem(remoteID: remoteID, parameters: invoiceItem))
    }
    */
}

// MARK: - Order
extension APIManager {

    func getOrderCollections(storeID: Int) -> Observable<DataResponse<[RemoteOrderCollection]>> {
        return requestList(Router.getOrderCollections(storeID: storeID))
    }

    func getOrderCollection(storeID: Int, orderDate: String) -> Observable<DataResponse<RemoteOrderCollection>> {
        return requestOne(Router.getOrderCollection(storeID: storeID, forDate: orderDate))
    }

    func postOrderCollection(storeID: Int, generationMethod: NewOrderGenerationMethod, returnUsage: Bool, periodLength: Int?) -> Observable<DataResponse<RemoteOrderCollection>> {
        return requestOne(Router.postOrderCollection(storeID: storeID, generationMethod: generationMethod,
                                                     returnUsage: returnUsage, periodLength: periodLength))
    }

    /// NOTE: I am designing this in accordance with how things should work, not how they currently do
    /// TODO: should remoteID be a separate argument?
    func putOrder(_ order: [String: Any]) -> Observable<DataResponse<RemoteOrder>> {
        return requestOne(Router.postOrder(order))
    }

}
