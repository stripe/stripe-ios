//
//  CheckoutSessionConfirmResponse.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/26/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Response model for the checkout session confirm endpoint (POST /v1/payment_pages/:session_id/confirm)
final class CheckoutSessionConfirmResponse: NSObject {
    let status: STPCheckoutSessionStatus
    let paymentStatus: STPCheckoutSessionPaymentStatus
    let paymentIntent: STPPaymentIntent?
    let setupIntent: STPSetupIntent?
    let allResponseFields: [AnyHashable: Any]

    init(
        status: STPCheckoutSessionStatus,
        paymentStatus: STPCheckoutSessionPaymentStatus,
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
              let paymentStatusString = response["payment_status"] as? String
        else { return nil }

        let status = STPCheckoutSessionStatus.status(from: statusString)
        let paymentStatus = STPCheckoutSessionPaymentStatus.paymentStatus(from: paymentStatusString)

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
