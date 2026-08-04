//
//  STPConfirmationTokenParams+ApplePay.swift
//  StripeApplePay
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPConfirmationTokenParams {
    /// Asynchronously builds `STPConfirmationTokenParams` from a `PKPayment`.
    ///
    /// Converts the Apple Pay token into a Stripe Token, then embeds it as
    /// `paymentMethodData` on the params — no separate PaymentMethod creation needed.
    @_spi(STP)
    public static func create(
        apiClient: STPAPIClient,
        payment: PKPayment,
        fallbackBillingDetails: StripeAPI.BillingDetails?,
        returnURL: String?,
        shipping: STPPaymentIntentShippingDetailsParams?,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        completion: @escaping (Result<STPConfirmationTokenParams, Error>) -> Void
    ) {
        StripeAPI.Token.create(apiClient: apiClient, payment: payment) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let token):
                // Billing contact address is already embedded in the Token.
                // Only supply email from fallbackBillingDetails if present, since Apple Pay
                // billing contacts typically don't include an email address.
                let billingDetails: STPPaymentMethodBillingDetails?
                let email = (payment.billingContact?.emailAddress).flatMap({ $0.isEmpty ? nil : $0 })
                    ?? fallbackBillingDetails?.email
                if let email {
                    billingDetails = STPPaymentMethodBillingDetails()
                    billingDetails?.email = email
                } else {
                    billingDetails = nil
                }

                let cardParams = STPPaymentMethodCardParams()
                cardParams.token = token.id
                let paymentMethodParams = STPPaymentMethodParams(
                    card: cardParams,
                    billingDetails: billingDetails,
                    metadata: nil
                )

                let params = STPConfirmationTokenParams()
                params.paymentMethodData = paymentMethodParams
                params.returnURL = returnURL
                params.shipping = shipping
                params.clientAttributionMetadata = clientAttributionMetadata
                completion(.success(params))
            }
        }
    }
}
