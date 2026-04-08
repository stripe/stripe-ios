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

    static func makeClosedSession() -> STPCheckoutSession {
        var json = makeOpenSessionJSON()
        json["status"] = "complete"
        json["payment_status"] = "paid"
        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }

    static func makeAdaptivePricingSession(
        currency: String = "usd",
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true
    ) -> STPCheckoutSession {
        var json: [AnyHashable: Any] = [
            "session_id": "cs_test_123",
            "client_secret": "cs_test_123_secret_abc",
            "livemode": false,
            "mode": "payment",
            "status": "open",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "currency": currency,
            "total_summary": [
                "subtotal": 1200,
                "total": 1200,
                "due": 1200,
            ],
            "developer_tool_context": [
                "adaptive_pricing": [
                    "active": adaptivePricingActive,
                ],
            ],
        ]

        if includeLocalizedPrices {
            var localCurrencyOption: [AnyHashable: Any] = [
                "currency": "gbp",
                "amount": 1000,
            ]
            if includeExchangeRateFields {
                localCurrencyOption["presentment_exchange_rate"] = "0.776917"
                localCurrencyOption["conversion_markup_bps"] = 400
            }
            json["adaptive_pricing_info"] = [
                "integration_currency": "usd",
                "integration_amount": 1200,
                "active_presentment_currency": currency,
                "local_currency_options": [localCurrencyOption],
            ]
        }

        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
