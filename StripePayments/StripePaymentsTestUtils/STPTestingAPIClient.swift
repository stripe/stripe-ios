//
//  STPTestingAPIClient.swift
//  StripePaymentsTestUtils
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

// Test account info:
// Account: acct_1G6m1pFY0qyl6XeW
// Dashboard login/pw: fetch mobile-payments-sdk-ci
public let STPTestingDefaultPublishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6"
// Test account in Australia
public let STPTestingAUPublishableKey = "pk_test_GNmlCJ6AFgWXm4mJYiyWSOWN00KIIiri7F"
// Test account in Mexico
public let STPTestingMEXPublishableKey = "pk_test_51GvAY5HNG4o8pO5lDEegY72rkF1TMiMyuTxSFJsmsH7U0KjTwmEf2VuXHVHecil64QA8za8Um2uSsFsfrG0BkzFo00sb1uhblF"
// Test account in SG
public let STPTestingSGPublishableKey = "pk_test_51H7oXMAOnZToJom1hqiSvNGsUVTrG1SaXRSBon9xcEp0yDFAxEh5biA4n0ty6paEsD5Mo5ps1b7Taj9WAHQzjup800m8A8Nc3u"
// Test account in Belgium
public let STPTestingBEPublishableKey = "pk_test_51HZi0VArGMi59tL4sIXUjwXbMiM5uSHVfsKjNXcepJ80C5niX4bCm5rJ3CeDI1vjZ5Mz55Phsmw9QqjoZTsBFoWh009RQaGx0R"
public let STPTestingINPublishableKey = "pk_test_51H7wmsBte6TMTRd4gph9Wm7gnQOKJwdVTCj30AhtB8MhWtlYj6v9xDn1vdCtKYGAE7cybr6fQdbQQtgvzBihE9cl00tOnrTpL9"
// Test account in Brazil
public let STPTestingBRPublishableKey = "pk_test_51JYFFjJQVROkWvqT6Hy9pW7uPb6UzxT3aACZ0W3olY8KunzDE9mm6OxE5W2EHcdZk7LxN6xk9zumFbZL8zvNwixR0056FVxQmt"
// Test account in Great Britain
public let STPTestingGBPublishableKey = "pk_test_51KmkHbGoesj9fw9QAZJlz1qY4dns8nFmLKc7rXiWKAIj8QU7NPFPwSY1h8mqRaFRKQ9njs9pVJoo2jhN6ZKSDA4h00mjcbGF7b"
// Test account in Malaysia
public let STPTestingMYPublishableKey = "pk_test_vGCjSmT6Idy5zwfGBKnlq5rd00JT2vbrHb"
public let STPTestingJPPublishableKey = "pk_test_51NpIYRIq2LmpyICoBLPaTxfWFW4I34pnWuBjKXf8CgOlVih7Ni6oDfPRHGTzBEnpsrHiPvqP2UyydilqY66BWp8N00mQCJ1PU5"
// Test account in France
public let STPTestingFRPublishableKey = "pk_test_51JtgfQKG6vc7r7YCU0qQNOkDaaHrEgeHgGKrJMNfuWwaKgXMLzPUA1f8ZlCNPonIROLOnzpUnJK1C1xFH3M3Mz8X00Q6O4GfUt"
// Test account in Spain
public let STPTestingESPublishableKey = "pk_test_51UAYPpERR7vmXYYfQCFmwWj2zkbVaeClb25LoYGZENFiKFF6PCoelE3lmqvwIJyR3cuSymwmVOI6aOoRviJEoO1y00afTTU0XO"
// Test account in Thailand
public let STPTestingTHPublishableKey = "pk_test_51NpEAWBgCYKNuUnnoBpaJZQYWOO6UpLtcioKggla08zpvDDy0cjfGKZdl5BsU8Gm5ilJNCqT7laCsqvyc0LndskG00pnPnJSpD"
// Test account for Naira card and Naira bank transfer
public let STPTestingNGPublishableKey = "pk_test_51PnmqMFoDYfWw3n43Igi4AQCH3GIizmq8WAm2AI5zA7vIlyG4mGqhRxFLmCjg38KOl6sJCr4T33FY2qWBunwXZYX00dOs0ukCL"
// Test account for Naira Wallet
public let STPTestingNGWalletPublishableKey = "pk_test_51QSODeDVpqbmmLClhGlSJmLpCSqphqTUx0CAPuiO4R9lbpQ1p4lEVXwGR4I3trSK9nce7F9m98Q4TspvrQ9gKZ0s00Z7wMj6Bf"
// Test account for Mondu
public let STPTestingMonduPublishableKey = "pk_test_51RQcmLL2ttF1aQ6KGGG8Qea5S4gvjnfOhUijlYg0TXy9LRhFAAMcUcHxyKT9CwbXn7A1uPoU6OJi0icb4SI0kFAQ0010GQbZsl"
// Test account in Germany
// Account token: acct_1PSnNaAlz2yHYCNZ
// Scenario link: https://admin.corp.stripe.com/scenarios?runId=scnrun*AZAoKlcYbwAAAIDN
public let STPTestingDEPublishableKey = "pk_test_51PSnNaAlz2yHYCNZgjajit4L8Hl1rDDPPCj9XhHNZWRSi4vwHhrHIbTgstLJptPSzwQVl1HlyqhwWRs1rBJHag8W00sM0SOXIL"
// Test account in Italy
// Account token: acct_1PSnETIFbdis1OxT
// Scenario link: https://admin.corp.stripe.com/scenarios?runId=scnrun*AZAoIbaznQAAAJ96
public let STPTestingITPublishableKey = "pk_test_51PSnETIFbdis1OxTALF4Z8ugUQpVS06UQDVahMSmwrbEYphjNYitXtOSqMPVKfzl3jukg6gLLrtZNnPlDrRbDpMd00U0tId6iv"
// Sandbox w/ payments orchestration rules, under US account
// See https://dashboard.stripe.com/acct_1T4pKXFRhicYlEF7/test/orchestration/rules/extn_test_61UEDJ3udBbhjozqU41FRhicYlEF7A4u/edit
public let STPTestingPaymentsOrchestrationPublishableKey = "pk_test_51T4pKXFRhicYlEF7yTT9Yv7W56S32foU0UlbE0zujkJOVEokHszMyuHi4k376ss1m4k57xym5wfWThb2Jek58K6y00fx7nEpgW"

public class STPTestingAPIClient: NSObject {
    public static let shared = STPTestingAPIClient()

    /// Set this to the Stripe SDK session for SWHttpTrafficRecorder recording to work correctly
    public var sessionConfig: URLSessionConfiguration = URLSession.shared.configuration

    /// - Parameters:
    ///   - account: nil for default or e.g. "au" for the Australia test account or "mex" for the Mexico test account
    ///   - apiVersion: nil for default, or a version with beta headers
    public func createPaymentIntent(
        withParams params: [String: Any]?,
        account: String? = nil,
        apiVersion: String? = nil,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createIntent(
            endpoint: "create_payment_intent",
            params: params,
            account: account,
            apiVersion: apiVersion,
            completion: completion
        )
    }

    /// - Parameters:
    ///   - account: nil for default or e.g. "au" for the Australia test account or "mex" for the Mexico test account
    ///   - apiVersion: nil for default, or a version with beta headers
    public func createSetupIntent(
        withParams params: [String: Any]?,
        account: String? = nil,
        apiVersion: String? = nil,
        completion: @escaping (String?, Error?) -> Void
    ) {
        createIntent(
            endpoint: "create_setup_intent",
            params: params,
            account: account,
            apiVersion: apiVersion,
            completion: completion
        )
    }

    public func createPaymentIntent(
        withParams params: [String: Any]?,
        account: String? = nil,
        apiVersion: String? = nil
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            createPaymentIntent(withParams: params, account: account, apiVersion: apiVersion) { clientSecret, error in
                Self.resume(continuation, clientSecret: clientSecret, error: error)
            }
        }
    }

    public func createSetupIntent(
        withParams params: [String: Any]?,
        account: String? = nil,
        apiVersion: String? = nil
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            createSetupIntent(withParams: params, account: account, apiVersion: apiVersion) { clientSecret, error in
                Self.resume(continuation, clientSecret: clientSecret, error: error)
            }
        }
    }

    private static func resume(
        _ continuation: CheckedContinuation<String, Error>,
        clientSecret: String?,
        error: Error?
    ) {
        if let clientSecret {
            continuation.resume(returning: clientSecret)
        } else {
            continuation.resume(throwing: error ?? NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue))
        }
    }

    private func createIntent(
        endpoint: String,
        params: [String: Any]?,
        account: String?,
        apiVersion: String?,
        completion: @escaping (String?, Error?) -> Void
    ) {
        let session = URLSession(configuration: sessionConfig)
        let url = URL(string: STPTestingAPIClient.STPTestingBackendURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let postData = try? JSONSerialization.data(
            withJSONObject: [
                "account": account ?? "",
                "create_params": params ?? [:],
                "version": apiVersion ?? STPAPIClient.apiVersion,
            ]
        )

        let uploadTask = session.uploadTask(with: request, from: postData) { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            if let error {
                completion(nil, error)
            } else if data == nil || httpResponse?.statusCode != 200 {
                DispatchQueue.main.async {
                    let errorString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    let apiError = NSError(
                        domain: STPError.stripeDomain,
                        code: STPErrorCode.apiError.rawValue,
                        userInfo: [
                            STPError.errorMessageKey: errorString,
                            NSLocalizedDescriptionKey: errorString,
                        ]
                    )
                    print(apiError)
                    completion(nil, apiError)
                }
            } else {
                var jsonError: Error?
                var json: Any?
                do {
                    json = try JSONSerialization.jsonObject(with: data ?? Data())
                } catch {
                    jsonError = error
                }
                DispatchQueue.main.async {
                    if let secret = (json as? [String: Any])?["secret"] as? String {
                        completion(secret, nil)
                    } else {
                        completion(nil, jsonError)
                    }
                }
            }
        }
        uploadTask.resume()
    }
}
