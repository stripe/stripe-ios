//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPTestingAPIClient.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import Stripe
import StripeCore

/// Test account info:
/// Account: acct_1G6m1pFY0qyl6XeW
/// Dashboard login/pw: fetch mobile-payments-sdk-ci
private let STPTestingDefaultPublishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6"
// Test account in Australia
private let STPTestingAUPublishableKey = "pk_test_GNmlCJ6AFgWXm4mJYiyWSOWN00KIIiri7F"
// Test account in Mexico
private let STPTestingMEXPublishableKey = "pk_test_51GvAY5HNG4o8pO5lDEegY72rkF1TMiMyuTxSFJsmsH7U0KjTwmEf2VuXHVHecil64QA8za8Um2uSsFsfrG0BkzFo00sb1uhblF"
// Test account in SG
private let STPTestingSGPublishableKey = "pk_test_51H7oXMAOnZToJom1hqiSvNGsUVTrG1SaXRSBon9xcEp0yDFAxEh5biA4n0ty6paEsD5Mo5ps1b7Taj9WAHQzjup800m8A8Nc3u"
// Test account in Belgium
private let STPTestingBEPublishableKey = "pk_test_51HZi0VArGMi59tL4sIXUjwXbMiM5uSHVfsKjNXcepJ80C5niX4bCm5rJ3CeDI1vjZ5Mz55Phsmw9QqjoZTsBFoWh009RQaGx0R"
private let STPTestingINPublishableKey = "pk_test_51H7wmsBte6TMTRd4gph9Wm7gnQOKJwdVTCj30AhtB8MhWtlYj6v9xDn1vdCtKYGAE7cybr6fQdbQQtgvzBihE9cl00tOnrTpL9"
// Test account in Brazil
private let STPTestingBRPublishableKey = "pk_test_51JYFFjJQVROkWvqT6Hy9pW7uPb6UzxT3aACZ0W3olY8KunzDE9mm6OxE5W2EHcdZk7LxN6xk9zumFbZL8zvNwixR0056FVxQmt"
// Test account in Great Britain
private let STPTestingGBPublishableKey = "pk_test_51KmkHbGoesj9fw9QAZJlz1qY4dns8nFmLKc7rXiWKAIj8QU7NPFPwSY1h8mqRaFRKQ9njs9pVJoo2jhN6ZKSDA4h00mjcbGF7b"
private let STPTestingBackendURL = "https://stp-mobile-ci-test-backend-e1b3.stripedemos.com/"


class STPTestingAPIClient: NSObject {
    // Set this to the Stripe SDK session for SWHTTPRecorder recording to work correctly
    var sessionConfig: URLSessionConfiguration?

    static let sharedClientVar = STPTestingAPIClient()

    class func shared() -> Self {
        // [Swiftify] `dispatch_once()` call was converted to the initializer of the `sharedClientVar` variable

        return sharedClientVar
    }

    override init() {
        super.init()
        sessionConfig = URLSession.shared.configuration
    }

    func createPaymentIntent(
        withParams params: [AnyHashable : Any]?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createPaymentIntent(
            withParams: params,
            account: nil,
            completion: completion)
    }

    func createPaymentIntent(
        withParams params: [AnyHashable : Any]?,
        account: String?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createPaymentIntent(
            withParams: params,
            account: account,
            apiVersion: nil,
            completion: completion)
    }

    func createPaymentIntent(
        withParams params: [AnyHashable : Any]?,
        account: String?,
        apiVersion: String?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string: STPTestingBackendURL + "create_payment_intent")

        var request: NSMutableURLRequest?
        if let url {
            request = NSMutableURLRequest(url: url)
        }
        request?.httpMethod = "POST"
        request?.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var postData: Data?
        do {
            postData = try JSONSerialization.data(
                withJSONObject: [
                    "account": account ?? "",
                    "create_params": params ?? [:],
                    "version": apiVersion ?? STPAPIClient.apiVersion,
                ],
                options: [])
        } catch {
        }

        var uploadTask: URLSessionUploadTask?
        if let request {
            uploadTask = session.uploadTask(
                with: request,
                from: postData) { data, response, error in
                    let httpResponse = response as? HTTPURLResponse
                    if error != nil {
                        completion(nil, error)
                    } else if data == nil || httpResponse?.statusCode != 200 {
                        DispatchQueue.main.async(execute: {
                            let errorStr = String(data: data, encoding: .utf8)
                            let userInfo = [
                                STPError.errorMessageKey: errorStr ?? "",
                                NSLocalizedDescriptionKey: errorStr ?? ""
                            ]
                            let apiError = Error(domain: STPError.stripeDomain, code: Int(STPAPIError), userInfo: userInfo) as? Error
                            if let apiError {
                                print("\(apiError)")
                            }
                            completion(nil, apiError!)
                        })
                    } else {
                        var jsonError: Error?
                        var json: Any?
                        do {
                            json = try JSONSerialization.jsonObject(with: data, options: [])
                        } catch let e {
                            jsonError = e
                        }

                        if json != nil && (json is [AnyHashable : Any]) && (json?["secret"] is NSString) {
                            DispatchQueue.main.async(execute: {
                                completion((json?["secret"] as? @escaping (String), nil)
                            })
                        } else {
                            DispatchQueue.main.async(execute: {
                                completion(nil, jsonError!)
                            })
                        }
                    }
                }
        }

        uploadTask?.resume()
    }

    func createSetupIntent(
        withParams params: [AnyHashable : Any]?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createSetupIntent(
            withParams: params,
            account: nil,
            completion: completion)
    }

    func createSetupIntent(
        withParams params: [AnyHashable : Any]?,
        account: String?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createSetupIntent(
            withParams: params,
            account: account,
            apiVersion: nil,
            completion: completion)
    }

    func createSetupIntent(
        withParams params: [AnyHashable : Any]?,
        account: String?,
        apiVersion: String?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string: STPTestingBackendURL + "create_setup_intent")

        var request: NSMutableURLRequest?
        if let url {
            request = NSMutableURLRequest(url: url)
        }
        request?.httpMethod = "POST"
        request?.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var postData: Data?
        do {
            postData = try JSONSerialization.data(
                withJSONObject: [
                    "account": account ?? "",
                    "create_params": params ?? [:],
                    "version": apiVersion ?? STPAPIClient.apiVersion,
                ],
                options: [])
        } catch {
        }

        var uploadTask: URLSessionUploadTask?
        if let request {
            uploadTask = session.uploadTask(
                with: request,
                from: postData) { data, response, error in
                    let httpResponse = response as? HTTPURLResponse

                    if error != nil {
                        completion(nil, error)
                    } else if data == nil || httpResponse?.statusCode != 200 {
                        DispatchQueue.main.async(execute: {
                            let errorStr = String(data: data, encoding: .utf8)
                            let userInfo = [
                                STPError.errorMessageKey: errorStr ?? "",
                                NSLocalizedDescriptionKey: errorStr ?? ""
                            ]
                            let apiError = Error(domain: STPError.stripeDomain, code: Int(STPAPIError), userInfo: userInfo) as? Error
                            if let apiError {
                                print("\(apiError)")
                            }
                            completion(nil, apiError!)
                        })
                    } else {
                        var jsonError: Error?
                        var json: Any?
                        do {
                            json = try JSONSerialization.jsonObject(with: data, options: [])
                        } catch let e {
                            jsonError = e
                        }

                        if json != nil && (json is [AnyHashable : Any]) && (json?["secret"] is NSString) {
                            DispatchQueue.main.async(execute: {
                                completion((json?["secret"] as? @escaping (String), nil)
                            })
                        } else {
                            DispatchQueue.main.async(execute: {
                                completion(nil, jsonError!)
                            })
                        }
                    }
                }
        }

        uploadTask?.resume()
    }
}
