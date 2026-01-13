//
//  CheckoutSessionConfirmResponse.swift
//  StripePaymentSheet
//
//  Created by Porter Hampson on 1/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Response model for the checkout session confirm endpoint (POST /v1/payment_pages/:session_id/confirm)
final class CheckoutSessionConfirmResponse: NSObject {
    enum Status: String {
        case open
        case complete
        case expired
    }

    enum PaymentStatus: String {
        case paid
        case unpaid
        case noPaymentRequired = "no_payment_required"
    }

    let status: Status
    let paymentStatus: PaymentStatus
    let paymentIntent: STPPaymentIntent?
    let setupIntent: STPSetupIntent?
    let allResponseFields: [AnyHashable: Any]

    init(
        status: Status,
        paymentStatus: PaymentStatus,
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.status = status
        self.paymentStatus = paymentStatus
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
              let status = Status(rawValue: statusString),
              let paymentStatusString = response["payment_status"] as? String,
              let paymentStatus = PaymentStatus(rawValue: paymentStatusString)
        else { return nil }

        // Parse payment intent if present
        let paymentIntent = (response["payment_intent"] as? [AnyHashable: Any])
            .flatMap { STPPaymentIntent.decodedObject(fromAPIResponse: $0) }

        // Parse setup intent if present
        let setupIntent = (response["setup_intent"] as? [AnyHashable: Any])
            .flatMap { STPSetupIntent.decodedObject(fromAPIResponse: $0) }

        return CheckoutSessionConfirmResponse(
            status: status,
            paymentStatus: paymentStatus,
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
            allResponseFields: response
        ) as? Self
    }
}
