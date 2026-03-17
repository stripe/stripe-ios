//
//  CheckoutTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet

enum CheckoutTestHelpers {
    static func makeOpenSessionJSON() -> [AnyHashable: Any] {
        [
            "session_id": "cs_test_123",
            "client_secret": "cs_test_123_secret_abc",
            "livemode": false,
            "mode": "payment",
            "status": "open",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "currency": "usd",
        ]
    }

    static func makeOpenSession(customerEmail: String? = nil) -> STPCheckoutSession {
        var json = makeOpenSessionJSON()
        json["customer_email"] = customerEmail
        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
