//
//  STPAPIClient.swift
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//
// NOTE: This is a simplified + modified version of Stripe's STPAPIClient. Will remove once API stack is moved to StripeCore

import Foundation
import UIKit

struct StripeAPIConfiguration {
    static let sharedUrlSessionConfiguration = URLSessionConfiguration.default
    static let STPSDKVersion = "2.1.3"
}

private let APIVersion = "2020-08-27"
private let APIBaseURL = "https://api.stripe.com/v1"

/// A client for making connections to the Stripe API.
class STPAPIClient: NSObject {
    /// The current version of this library.
    @objc static let STPSDKVersion = StripeAPIConfiguration.STPSDKVersion

    /// A shared singleton API client.
    /// By default, the SDK uses this instance to make API requests
    /// eg in STPPaymentHandler, STPPaymentContext, STPCustomerContext, etc.
    static let shared: STPAPIClient = STPAPIClient()


    /// The client's publishable key.
    /// NOTE: Not doing any validation with this version. Will use STPAPIClient with validation once ported
    var publishableKey: String?

    /// The API version used to communicate with Stripe.
    static let apiVersion = APIVersion

    static let maxRetries = 3
    
    // MARK: Internal/private properties
    var apiURL: URL! = URL(string: APIBaseURL)
    let urlSession = URLSession(configuration: StripeAPIConfiguration.sharedUrlSessionConfiguration)

    private var sourcePollers: [String: NSObject]?
    private var sourcePollersQueue: DispatchQueue?

    /// Returns `true` if `publishableKey` is actually a user key, `false` otherwise.
    private var publishableKeyIsUserKey: Bool {
        return publishableKey?.hasPrefix("uk_") ?? false
    }

    // MARK: Initializers
    override init() {
        super.init()
        // NOTE: (jaimepark) This SDK isn't using PaymentConfiguration
        //configuration = STPPaymentConfiguration.shared
        sourcePollers = [:]
        sourcePollersQueue = DispatchQueue(label: "com.stripe.sourcepollers")
    }

    /// Initializes an API client with the given publishable key.
    /// - Parameter publishableKey: The publishable key to use.
    /// - Returns: An instance of STPAPIClient.
    @objc
    public convenience init(publishableKey: String) {
        self.init()
        self.publishableKey = publishableKey
    }

    func configuredRequest(for url: URL, additionalHeaders: [String: String] = [:])
        -> NSMutableURLRequest
    {
        let request = NSMutableURLRequest(url: url)
        var headers = authorizationHeader()
        for (k, v) in additionalHeaders { headers[k] = v }  // additionalHeaders can overwrite defaultHeaders
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
    
    func authorizationHeader(with secret: String? = nil) -> [String: String] {
        authorizationHeader(using: secret)
    }

    func authorizationHeader(using secretKey: String?) -> [String: String] {
        var authorizationBearer = publishableKey ?? ""
        if let secretKey = secretKey {
            authorizationBearer = secretKey
        }
        let headers: [String: String] = [
            "Authorization": "Bearer " + authorizationBearer
        ]
        return headers
    }
}

extension URLSession {
    func stp_performDataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void,
                  retryCount: Int = StripeAPI.maxRetries) {
        let task = dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 429,
               retryCount > 0 {
                // Add some backoff time with a little bit of jitter:
                let delayTime = TimeInterval(
                    pow(Double(1 + StripeAPI.maxRetries - retryCount), Double(2)) + .random(in: 0..<0.5)
                )

                if #available(iOS 13.0, *) {
                    let fireDate = Date() + delayTime
                    self.delegateQueue.schedule(after: .init(fireDate)) {
                        self.stp_performDataTask(with: request, completionHandler: completionHandler, retryCount: retryCount - 1)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                        self.delegateQueue.addOperation {
                            self.stp_performDataTask(with: request, completionHandler: completionHandler, retryCount: retryCount - 1)
                        }
                    }
                }
            } else {
                completionHandler(data, response, error)
            }
        }
        task.resume()
    }
}
