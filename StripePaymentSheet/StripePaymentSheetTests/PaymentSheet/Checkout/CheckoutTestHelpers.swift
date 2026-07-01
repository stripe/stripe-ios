//
//  CheckoutTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet

extension Checkout.Amount {
    /// Test helper for constructing a ``Checkout/Amount`` from a minor-units integer.
    static func testValue(_ minorUnits: Int, currency: String = "usd") -> Checkout.Amount {
        return STPCheckoutSession.makeAmount(minorUnits, currency: currency)
    }
}

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
            "elements_session": [
                "session_id": "es_test",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
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

    static func makeOpenSession(allowedCountries: [String]) -> STPCheckoutSession {
        var json = makeOpenSessionJSON()
        json["shipping_address_collection"] = ["allowed_countries": allowedCountries]
        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }

    static func makeAdaptivePricingSession(
        currency: String = "usd",
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true,
        integrationAmount: Int = 1200,
        localAmount: Int = 1000
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
            "elements_session": [
                "session_id": "es_test",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
            "total_summary": [
                "subtotal": integrationAmount,
                "total": integrationAmount,
                "due": integrationAmount,
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
                "amount": localAmount,
            ]
            if includeExchangeRateFields {
                localCurrencyOption["presentment_exchange_rate"] = "0.776917"
                localCurrencyOption["conversion_markup_bps"] = 400
            }
            json["adaptive_pricing_info"] = [
                "integration_currency": "usd",
                "integration_amount": integrationAmount,
                "active_presentment_currency": currency,
                "local_currency_options": [localCurrencyOption],
            ]
        }

        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
