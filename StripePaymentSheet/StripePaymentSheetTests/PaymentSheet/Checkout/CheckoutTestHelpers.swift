//
//  CheckoutTestHelpers.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

extension Checkout.Amount {
    /// Test helper for constructing a ``Checkout/Amount`` from a minor-units integer.
    static func testValue(_ minorUnits: Int, currency: String = "usd") -> Checkout.Amount {
        return STPCheckoutSession.makeAmount(minorUnits, currency: currency)
    }
}

// MARK: - Shared Mock Delegates

@MainActor
class MockCheckoutDelegate: CheckoutDelegate {
    var lastSession: Checkout.Session?
    var updateSessionCallCount = 0
    var beginLoadingCallCount = 0
    var finishLoadingCallCount = 0
    var onUpdateSession: (() -> Void)?

    func checkoutDidBeginLoading(_ checkout: Checkout) {
        beginLoadingCallCount += 1
    }

    func checkoutDidFinishLoading(_ checkout: Checkout) {
        finishLoadingCallCount += 1
    }

    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session) {
        updateSessionCallCount += 1
        lastSession = session
        onUpdateSession?()
    }
}

@MainActor
class MockCheckoutIntegrationDelegate: CheckoutIntegrationDelegate {
    var isSheetPresented: Bool = false
    var checkoutDidUpdateCallCount = 0
    var lastCheckout: Checkout?
    var shouldThrow: Error?
    var onUpdate: (() -> Void)?

    func checkoutDidUpdate(_ checkout: Checkout) async throws {
        checkoutDidUpdateCallCount += 1
        lastCheckout = checkout
        onUpdate?()
        if let error = shouldThrow { throw error }
    }
}

// MARK: - Emission Recorder

@MainActor
class CheckoutEmissionRecorder {
    var sessions: [Checkout.Session] = []
    var loading: [Bool] = []
    private var subscriptions = Set<AnyCancellable>()

    init(_ checkout: Checkout) {
        checkout.$session.dropFirst().sink { [weak self] in self?.sessions.append($0) }
            .store(in: &subscriptions)
        checkout.$isLoading.dropFirst().sink { [weak self] in self?.loading.append($0) }
            .store(in: &subscriptions)
    }
}

// MARK: - Shared Helpers

enum CheckoutTestHelpers {

    // MARK: - Base JSON building blocks

    static let minimalElementsSessionJSON: [String: Any] = [
        "session_id": "es_test",
        "payment_method_preference": ["ordered_payment_method_types": ["card"]],
    ]

    static let baseSessionJSON: [String: Any] = [
        "session_id": "cs_test",
        "object": "checkout.session",
        "livemode": false,
        "mode": "payment",
        "payment_status": "unpaid",
        "payment_method_types": ["card"],
        "elements_session": minimalElementsSessionJSON,
    ]

    /// Creates an `STPCheckoutSession` from `baseSessionJSON` with top-level key overrides.
    /// To test field *absence*, mutate `baseSessionJSON` directly instead.
    static func makeSession(_ overrides: [String: Any] = [:]) -> STPCheckoutSession {
        let json = makeSessionJSON(overrides)
        guard let session = STPCheckoutSession.decodedObject(fromAPIResponse: json) else {
            fatalError("makeSession: failed to decode STPCheckoutSession from \(json)")
        }
        return session
    }

    static func makeSessionJSON(_ overrides: [String: Any] = [:]) -> [String: Any] {
        baseSessionJSON.merging(overrides) { _, new in new }
    }

    // MARK: - Checkout-flow helpers

    static func makeCheckoutWithOpenSession() async -> Checkout {
        let session = makeOpenSession()
        return await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
    }

    static func makeOpenSessionJSON() -> [AnyHashable: Any] {
        makeSessionJSON([
            "session_id": "cs_test_123",
            "client_secret": "cs_test_123_secret_abc",
            "status": "open",
            "currency": "usd",
        ])
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
        var json: [AnyHashable: Any] = makeOpenSessionJSON()
        json["currency"] = currency
        json["total_summary"] = [
            "subtotal": integrationAmount,
            "total": integrationAmount,
            "due": integrationAmount,
        ]
        json["developer_tool_context"] = [
            "adaptive_pricing": [
                "active": adaptivePricingActive,
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
