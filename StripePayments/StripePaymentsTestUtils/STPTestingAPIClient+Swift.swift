//
//  STPTestingAPIClient+Swift.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 6/25/23.
//

import Foundation
@_exported import StripePaymentsObjcTestUtils

extension STPTestingAPIClient {
    public static var shared: STPTestingAPIClient {
        return .shared()
    }

    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        customerID: String? = nil,
        confirm: Bool = false,
        otherParams: [String: Any] = [:],
        completion: @escaping (Result<(String), Error>) -> Void
    ) {
        var params = [String: Any]()
        params["amount"] = 5050
        params["currency"] = currency
        params["payment_method_types"] = types
        params["confirm"] = confirm
        if let paymentMethodID {
            params["payment_method"] = paymentMethodID
        }
        if let customerID {
            params["customer"] = customerID
        }
        params.merge(otherParams) { _, b in b }

        createPaymentIntent(
            withParams: params,
            account: merchantCountry
        ) { clientSecret, error in
            guard let clientSecret = clientSecret,
                  error == nil
            else {
                completion(.failure(error!))
                return
            }

            completion(.success(clientSecret))
        }
    }

    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        customerID: String? = nil,
        confirm: Bool = false,
        otherParams: [String: Any] = [:]
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            fetchPaymentIntent(
                types: types,
                currency: currency,
                merchantCountry: merchantCountry,
                paymentMethodID: paymentMethodID,
                customerID: customerID,
                confirm: confirm,
                otherParams: otherParams
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchSetupIntent(
        types: [String],
        merchantCountry: String? = "us",
        paymentMethodID: String? = nil,
        customerID: String? = nil,
        confirm: Bool = false,
        otherParams: [String: Any] = [:]
    ) async throws -> String {
        var params = [String: Any]()
        params["payment_method_types"] = types
        params["confirm"] = confirm
        if let paymentMethodID {
            params["payment_method"] = paymentMethodID
        }
        if let customerID {
            params["customer"] = customerID
        }
        params.merge(otherParams) { _, b in b }
        return try await withCheckedThrowingContinuation { continuation in
            createSetupIntent(withParams: params,
                              account: merchantCountry) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    continuation.resume(throwing: error!)
                    return
                }
                continuation.resume(returning: clientSecret)
            }
        }
    }
}
