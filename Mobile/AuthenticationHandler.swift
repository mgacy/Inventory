//
//  AuthenticationHandler.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/13/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Alamofire
import KeychainAccess
import SwiftyJSON

class AuthenticationHandler: RequestAdapter, RequestRetrier {
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
    //private var refreshToken: String

    // Mine
    private var email: String
    private var password: String

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

    // MARK: Lifecycle

    public init(keychain: Keychain, email: String, password: String) {
        // OAuth2
        //self.clientID = clientID
        self.baseURLString = Router.baseURLString
        //self.accessToken = accessToken
        //self.refreshToken = refreshToken

        // Mine
        self.keychain = keychain
        self.email = email
        self.password = password
        /*
        // If we don't have an accessToken, we go ahead and get one from the start
        if accessToken == nil {
            log.info("No accessToken; logging in ...")
            login(completion: {(succeeded: Bool) -> Void in
                switch succeeded {
                case true:
                    log.info("We logged in")
                case false:
                    log.info("We were unable to log in")
                }
            })
        } else {
            log.info("Have accessToken")
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

    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }

        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            log.warning("401: invalid token (probably) ...")
            requestsToRetry.append(completion)

            if !isRefreshing {
                refreshTokens { [weak self] succeeded, accessToken, refreshToken in
                    guard let strongSelf = self else { return }

                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }

                    if let accessToken = accessToken, let refreshToken = refreshToken {

                        /* We do not actually use refreshToken at the moment; in order to keep these methods as close as
                         * possible to the example `OAuth2Handler` given in the Alamofire README, we pass the message we
                         * want to log
                         */
                        log.info(refreshToken)
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

        // Log in again
        log.info("Logging in again to refreshTokens ...")
        sessionManager.request(Router.login(email: email, password: password))
            .responseJSON { [weak self] response in
                guard let strongSelf = self else { return }

                if let json = response.result.value as? [String: Any], let accessToken = json["token"] as? String {
                    log.verbose("Received new access token ...")
                    // We pass a string for `refreshToken` to keep `.should()` as close to the `OAuth2Handler` example
                    // from the Alamofire README as possible
                    completion(true, accessToken, "Updating accessToken ...")
                } else {
                    log.error("Attempt to login again failed")
                    completion(false, nil, nil)
                }

                strongSelf.isRefreshing = false
        }
    }

    // MARK: - Request Token

    public func login(completion: @escaping (JSON?, Error?) -> Void) {
        sessionManager.request(Router.login(email: email, password: password))
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    // log.verbose("\(#function) - response: \(response)")

                    let json = JSON(value)
                    guard let token = json["token"].string else {
                        //log.error("\(#function) FAILED : unable to get token")
                        return completion(nil, BackendError.authentication(
                            error: BackendError.myError(error: "Unable to parse token from response.")))
                    }
                    self.accessToken = token
                    completion(json, nil)

                case .failure(let error):
                    //log.error("\(#function) FAILED : unable to get token : \(error)")
                    completion(nil, BackendError.authentication(error: error))
                }
        }
    }

}
