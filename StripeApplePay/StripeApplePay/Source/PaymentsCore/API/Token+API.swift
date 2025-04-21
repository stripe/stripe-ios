//
//  Token+API.swift
//  StripeApplePay
//
//  Created by David Estes on 8/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

extension StripeAPI.Token {
    /// A callback to be run with a token response from the Stripe API.
    /// - Parameters:
    ///   - token: The Stripe token from the response. Will be nil if an error occurs. - seealso: STPToken
    ///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
    @_spi(StripeApplePayTokenization) public typealias TokenCompletionBlock = (Result<StripeAPI.Token, Error>) -> Void

    /// Converts a PKPayment object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    @_spi(StripeApplePayTokenization) public static func create(
        apiClient: STPAPIClient = .shared,
        payment: PKPayment,
        completion: @escaping TokenCompletionBlock
    ) {
        // Internal note: @_spi(StripeApplePayTokenization) is intended for limited public use. See https://docs.google.com/document/d/1Z9bTUBvDDufoqTaQeI3A0Cxdsoj_D0IkxdWX-GB-RTQ
        let params = payment.stp_tokenParameters(apiClient: apiClient)
        create(
            apiClient: apiClient,
            parameters: params,
            completion: completion
        )
    }

    static func create(
        apiClient: STPAPIClient = .shared,
        parameters: [String: Any],
        completion: @escaping TokenCompletionBlock
    ) {
        let tokenType = STPAnalyticsClient.tokenType(fromParameters: parameters)
        var mutableParams = parameters
        STPTelemetryClient.shared.addTelemetryFields(toParams: &mutableParams)
        mutableParams = STPAPIClient.paramsAddingPaymentUserAgent(mutableParams)
        STPAnalyticsClient.sharedClient.logTokenCreationAttempt(tokenType: tokenType)
        apiClient.post(resource: Resource, parameters: mutableParams, completion: completion)
        STPTelemetryClient.shared.sendTelemetryData()
    }

    static let Resource = "tokens"
}

extension PKPayment {
    func stp_tokenParameters(apiClient: STPAPIClient) -> [String: Any] {
        let paymentString = String(data: self.token.paymentData, encoding: .utf8)
        var payload: [String: Any] = [:]
        payload["pk_token"] = paymentString
        if let billingContact = self.billingContact {
            payload["card"] = billingContact.addressParams
        }

        assert(
            !((paymentString?.count ?? 0) == 0
                && apiClient.publishableKey?.hasPrefix("pk_live") ?? false),
            "The pk_token is empty. Using Apple Pay with an iOS Simulator while not in Stripe Test Mode will always fail."
        )

        let paymentInstrumentName = self.token.paymentMethod.displayName
        if let paymentInstrumentName = paymentInstrumentName {
            payload["pk_token_instrument_name"] = paymentInstrumentName
        }

        let paymentNetwork = self.token.paymentMethod.network
        if let paymentNetwork = paymentNetwork {
            // Note: As of SDK 20.0.0, this will return `PKPaymentNetwork(_rawValue: MasterCard)`.
            // We're intentionally leaving it this way: See RUN_MOBILESDK-125.
            payload["pk_token_payment_network"] = paymentNetwork
        }

        var transactionIdentifier = self.token.transactionIdentifier
        if transactionIdentifier != "" {
            if self.stp_applepay_isSimulated() {
                transactionIdentifier = PKPayment.stp_applepay_testTransactionIdentifier()
            }
            payload["pk_token_transaction_id"] = transactionIdentifier
        }

        return payload
    }
}
