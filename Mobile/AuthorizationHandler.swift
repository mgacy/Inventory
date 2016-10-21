//
//  AuthorizationHandler.swift
//  Playground
//
//  Created by Mathew Gacy on 10/13/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import Alamofire
import KeychainAccess
import SwiftyJSON

class AuthorizationHandler: RequestAdapter {
    // private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
    
    static let sharedInstance = AuthorizationHandler()
    
    private let sessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    private var baseURLString: String
    private var email: String?
    private var password: String?   // TODO: store this or just get from keychain when needed?
    private var accessToken: String?
    
    private let keychain: Keychain
    
    public var userExists: Bool {
        if self.password != nil {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Lifecycle

    public init() {
        self.baseURLString = Router.baseURLString
        
        // TODO: get email from keychain or settings?
        // TODO: handle absence of email / login
        self.email = "***REMOVED***"
        self.password = "***REMOVED***"
        
        // TODO: do I need to handle absence of service?
        keychain = Keychain(service: "***REMOVED***")
        
        /*
        // Handle password
        if let password = try? keychain.get(self.email!) {
            self.password = password
        } else {
            print("\nDidn't get password")
            self.password = "***REMOVED***"
            keychain[email!] = self.password
            //self.password = ""
        }
        */
    }

    // MARK: - RequestAdapter
    
    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        // TODO: include call to requestToken if accessToken == nil?
        if let accessToken = accessToken, let url = urlRequest.url, url.absoluteString.hasPrefix(baseURLString) {
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            return urlRequest
        }

        return urlRequest
    }
    
    // MARK: - RequestRetrier
    
    // public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) { }
    
    // MARK: - Private - Refresh Tokens
    
    // private func refreshTokens(completion: @escaping RefreshCompletion) { }
    
    // MARK: - Request Token
    
    func requestToken(completionHandler: @escaping (Bool) -> Void) {
         if let email = self.email, let password = self.password {
        
            // TODO: use sessionManager.request?
            Alamofire.request(Router.login(email: email, password: password))
                .responseJSON { response in
                    if response.result.isSuccess, let token = JSON(response.result.value)["token"].string {
                        self.accessToken = token
                        completionHandler(true)
                    } else {
                        // TODO: add logging or pass more error info on to handler
                        print("Problem getting token")
                        completionHandler(false)
                    }
            }
         } else {
            // TODO: how to handle this?
            completionHandler(false)
        }
    }
    
}

