//
//  STPPaymentMethodParams+ApplePay.swift
//  StripeApplePay
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPPaymentMethodParams {
    /// Asynchronously builds `STPPaymentMethodParams` from a `PKPayment`.
    ///
    /// Decrypts the Apple Pay token into a Stripe Token and embeds it as
    /// the card token on the params, ready for `createPaymentMethod`.
    @_spi(STP)
    public static func create(
        apiClient: STPAPIClient,
        payment: PKPayment,
        fallbackBillingDetails: StripeAPI.BillingDetails?,
        completion: @escaping (Result<STPPaymentMethodParams, Error>) -> Void
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
                completion(.success(STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)))
            }
        }
    }
}
