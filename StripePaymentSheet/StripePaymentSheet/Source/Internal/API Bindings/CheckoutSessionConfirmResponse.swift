//
//  CheckoutSessionConfirmResponse.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/26/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Response model for the CheckoutSession confirm endpoint (POST /v1/payment_pages/:session_id/confirm)
final class CheckoutSessionConfirmResponse: NSObject {
    /// The PaymentIntent for this session, if in `payment` or `subscription` mode.
    ///
    /// Contains payment details including amount, currency, payment method, and status.
    /// `nil` when session is in `setup` mode.
    let paymentIntent: STPPaymentIntent?
    /// The SetupIntent for this session, if in `setup` mode.
    ///
    /// Contains information about setting up a payment method for future use without
    /// immediate charge. `nil` when session is in `payment` or `subscription` mode.
    let setupIntent: STPSetupIntent?
    let allResponseFields: [AnyHashable: Any]

    init(
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.paymentIntent = paymentIntent
        self.setupIntent = setupIntent
        self.allResponseFields = allResponseFields
        super.init()
    }
}

extension CheckoutSessionConfirmResponse: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
              let statusString = response["status"] as? String,
              let paymentStatusString = response["payment_status"] as? String
        else { return nil }

        // Parse payment intent if present
        let paymentIntent = (response["payment_intent"] as? [AnyHashable: Any])
            .flatMap { STPPaymentIntent.decodedObject(fromAPIResponse: $0) }

        // Parse setup intent if present
        let setupIntent = (response["setup_intent"] as? [AnyHashable: Any])
            .flatMap { STPSetupIntent.decodedObject(fromAPIResponse: $0) }

        return CheckoutSessionConfirmResponse(
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
            allResponseFields: response
        ) as? Self
    }
}

extension CheckoutSessionConfirmResponse {
    /// Extracts the client secret from the confirm response based on checkout session mode.
    /// - Parameter mode: The checkout session mode (payment, setup, or subscription)
    /// - Returns: The client secret string from the underlying intent
    /// - Throws: PaymentSheetError if the expected intent is missing
    func clientSecret(for mode: STPCheckoutSessionMode) throws -> String {
        switch mode {
        case .setup:
            guard let setupIntent = setupIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing setup intent in confirm response")
            }
            return setupIntent.clientSecret
        case .payment, .subscription:
            guard let paymentIntent = paymentIntent else {
                throw PaymentSheetError.unknown(debugDescription: "Missing payment intent in confirm response")
            }
            return paymentIntent.clientSecret
        case .unknown:
            throw PaymentSheetError.unknown(debugDescription: "Unknown checkout session mode")
        }
    }
}
