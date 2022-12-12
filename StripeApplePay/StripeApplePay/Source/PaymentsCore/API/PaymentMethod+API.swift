//
//  PaymentMethod+API.swift
//  StripeApplePay
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

extension StripeAPI.PaymentMethod {
    /// A callback to be run with a PaymentMethod response from the Stripe API.
    /// - Parameters:
    ///   - paymentMethod: The Stripe PaymentMethod from the response. Will be nil if an error occurs. - seealso: PaymentMethod
    ///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
    @_spi(STP) public typealias PaymentMethodCompletionBlock = (
        Result<StripeAPI.PaymentMethod, Error>
    ) -> Void

    static func create(
        apiClient: STPAPIClient = .shared,
        params: StripeAPI.PaymentMethodParams,
        completion: @escaping PaymentMethodCompletionBlock
    ) {
        STPAnalyticsClient.sharedClient.logPaymentMethodCreationAttempt(
            paymentMethodType: params.type.rawValue
        )
        apiClient.post(resource: Resource, object: params, completion: completion)
    }

    /// Converts a PKPayment object into a Stripe Payment Method using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe source (and any errors that may have occurred).
    @_spi(STP) public static func create(
        apiClient: STPAPIClient = .shared,
        payment: PKPayment,
        completion: @escaping PaymentMethodCompletionBlock
    ) {
        StripeAPI.Token.create(apiClient: apiClient, payment: payment) { (result) in
            guard let token = try? result.get() else {
                if case .failure(let error) = result {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError.stp_genericConnectionError()))
                }
                return
            }
            var cardParams = StripeAPI.PaymentMethodParams.Card()
            cardParams.token = token.id
            let billingDetails = StripeAPI.BillingDetails(from: payment)
            var paymentMethodParams = StripeAPI.PaymentMethodParams(type: .card, card: cardParams)
            paymentMethodParams.billingDetails = billingDetails
            Self.create(apiClient: apiClient, params: paymentMethodParams, completion: completion)
        }
    }

    static let Resource = "payment_methods"
}
