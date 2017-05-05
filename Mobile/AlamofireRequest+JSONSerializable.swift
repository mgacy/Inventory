//
//  AlamofireRequest+JSONSerializable.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2016-04-14.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// NOTE: this is taken from Alamofire README
// NOTE: See "iOS Apps with REST APIs" Ch. 3.4 for an explanation of what is going on here

enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case authentication(error: Error)
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
    case myError(error: String)
}

// MARK: - ResponseObjectSerializable
protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: Any)
    //init?(response: HTTPURLResponse, representation: SwiftyJSON.JSON)
    //init?(json: SwiftyJSON.JSON)
}

// MARK: - ResponseCollectionSerializable
protocol ResponseCollectionSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self]
}

extension ResponseCollectionSerializable where Self: ResponseObjectSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self] {
        var collection: [Self] = []

        if let representation = representation as? [[String: Any]] {
            for itemRepresentation in representation {
                if let item = Self(response: response, representation: itemRepresentation) {
                    collection.append(item)
                }
            }
        }

        return collection
    }
}

// MARK: - DataRequest
extension DataRequest {

    @discardableResult
    func responseObject<T: ResponseObjectSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self
    {
        // Create response serializer working with our generic `T` type implementing ResponseObjectSerializable protocol
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }

            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)

            /*
            // EDIT
            switch result {
            case .failure(let error):
                return .failure(BackendError.jsonSerialization(error: error))
            case .success(let value):
                print("Value: \(value)")
                let json = SwiftyJSON.JSON(value)
                // TODO: check for "message" errors in the JSON
                if let errorMessage = json["message"].string {
                    return .failure(BackendError.myError(error: "Message errors in JSON"))
                }
            
                guard let responseObject = T(json: json) else {
                    return .failure(BackendError.myError(error: "Object could not be created from JSON."))
                }
            
            }
            // /Edit
            */

            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            /*
            /// NOTE: my changes
            let json = SwiftyJSON.JSON(jsonObject)
            if let errorMessage = json["message"].string {
                return .failure(BackendError.myError(error: "Message errors in JSON - \(errorMessage)"))
            }

            guard let responseObject = T(json: json) else {
                return .failure(BackendError.objectSerialization(reason: "JSON could not be serialized: \(jsonObject)"))
            }
            */

            guard let response = response, let responseObject = T(response: response, representation: jsonObject) else {
                return .failure(BackendError.objectSerialization(reason: "JSON could not be serialized: \(jsonObject)"))
            }

            return .success(responseObject)
        }

        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }

    @discardableResult
    func responseCollection<T: ResponseCollectionSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<[T]>) -> Void)
        -> Self
    {
        // Create response serializer working with our generic `T` type implementing ResponseObjectSerializable protocol
        let responseSerializer = DataResponseSerializer<[T]> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }

            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)

            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }

            /*
            /// NOTE: my changes
            let json = SwiftyJSON.JSON(jsonObject)
            if let errorMessage = json["message"].string {
                return .failure(BackendError.myError(error: "Message errors in JSON - \(errorMessage)"))
            }
                        
            var responseObjects: [T] = []
            for (_, item) in json {
                if let object = T(json: item) {
                    responseObjects.append(object)
                }
            }
            
            return .success(responseObjects)
            */

            guard let response = response else {
                let reason = "Response collection could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(reason: reason))
            }

            return .success(T.collection(from: response, withRepresentation: jsonObject))
        }

        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }

}
