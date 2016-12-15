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

class AuthorizationHandler: RequestAdapter, RequestRetrier {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void

    private let sessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        return Alamofire.SessionManager(configuration: configuration)
    }()

    private let lock = NSLock()

    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []

    private let keychain: Keychain

    // OAuth2
    // private var clientID: String
    private var baseURLString: String
    //private var refreshToken: String?

    // Mine

    // TODO: remove hard-coded email
    private let email = "***REMOVED***"
    //private let email: String? = "***REMOVED***"

    private var password: String? {
        set {
            //guard let email = email else { return }

            if let valueToSave = newValue {
                keychain[email] = valueToSave
            } else { // they set it to nil, so delete it
                keychain[email] = nil
            }
        }
        get {
            //guard let email = email else { return nil }

            // try to load from keychain
            guard let pass1 = try? keychain.get(email) else {
                print("FAILED: unable to access keychain"); return nil
            }
            if let pass2 = pass1 {
                print("Got password from keychain")
                return pass2
            } else {
                // TODO: remove hard-coded password
                print("Using hard-coded password")
                let defaultPass = "***REMOVED***"

                keychain[email] = defaultPass
                return defaultPass
            }
        }
    }

    private var accessToken: String? {
        set {
            if let valueToSave = newValue {
                keychain["authToken"] = valueToSave
            } else { // they set it to nil, so delete it
                keychain["authToken"] = nil
            }
        }
        get {
            // try to load from keychain
            if let token = try? keychain.get("authToken") {
                return token
            } else {
                return nil
            }
        }
    }

    public var userExists: Bool {
        if self.password != nil {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Lifecycle

    public init() {
        // OAuth2

        //self.clientID = clientID
        self.baseURLString = Router.baseURLString
        //self.accessToken = accessToken
        //self.refreshToken = refreshToken

        // Mine

        // TODO: do I need to handle absence of service?
        keychain = Keychain(service: "***REMOVED***")

        // TODO: handle absence of email

        // If we don't have an accessToken, we go ahead and get one from the start
        if accessToken == nil {
            print("No accessToken; logging in ...")
            login(completion: loginCompletion)
        } else {
            print("Have accessToken")
        }
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

    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }

        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            print("401: invalid token (probably) ...")
            requestsToRetry.append(completion)

            if !isRefreshing {
                refreshTokens { [weak self] succeeded, accessToken, refreshToken in
                    guard let strongSelf = self else { return }

                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }

                    if let accessToken = accessToken, let refreshToken = refreshToken {

                        /* NOTE: we do not actually use refreshToken at the moment
                         * In order to keep these methods as close as possible to the example
                         * OAuth2Handler given in the Alamofire README, we pass the message we
                         * want to print
                         */

                        print(refreshToken)
                        strongSelf.accessToken = accessToken
                        //strongSelf.refreshToken = refreshToken
                    }

                    strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(false, 0.0)
        }
    }

    // MARK: - Private - Refresh Tokens

    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }

        isRefreshing = true

        guard let password = password else {
            debugPrint("\(#function) FAILED : unable to get password"); return
        }

        // Log in again
        print("Logging in again to refreshTokens ...")
        sessionManager.request(Router.login(email: email, password: password))
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }

                if let accessToken = JSON(response.result.value!)["token"].string {
                    print("Received new access token ...")
                    // NOTE - we pass a string for refreshToken to keep should() as close to the
                    //        example from the Alamofire README as possible
                    completion(true, accessToken, "Updating accessToken ...")
                } else {
                    print("Attempt to login again failed")
                    completion(false, nil, nil)
                }

                strongSelf.isRefreshing = false
        }
    }

    // MARK: - My Stuff

    public func login(completion: @escaping (Bool) -> Void) {

        guard let password = password else {
            debugPrint("\(#function) FAILED : unable to get password"); return
        }

        sessionManager.request(Router.login(email: email, password: password))
            .responseJSON { response in
                if response.result.isSuccess, let token = JSON(response.result.value!)["token"].string {
                    self.accessToken = token
                    completion(true)
                } else {
                    // TODO: add logging or pass more error info on to handler
                    print("Problem getting token")
                    completion(false)
                }
        }
    }

    func loginCompletion(_ succeeded: Bool) -> Void {
        switch succeeded {
        case true:
            print("We logged in")
        case false:
            print("We were unable to log in")
        }
    }

}

