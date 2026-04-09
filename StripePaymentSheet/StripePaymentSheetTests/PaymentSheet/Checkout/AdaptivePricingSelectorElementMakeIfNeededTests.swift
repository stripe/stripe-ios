//
//  AdaptivePricingSelectorElementMakeIfNeededTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/30/26.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

@MainActor
final class AdaptivePricingSelectorElementMakeIfNeededTests: XCTestCase {

    func testReturnsNilWhenIsFlowController() {
        let session = makeAdaptivePricingSession()
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: .checkoutSession(session),
            isFlowController: true,
            appearance: .default
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenIntentIsNotCheckoutSession() {
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1000, currency: "usd"), confirmHandler: { _, _, _ in }))
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: intent,
            isFlowController: false,
            appearance: .default
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenAdaptivePricingNotActive() {
        let session = makeSession(adaptivePricingActive: false)
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: .checkoutSession(session),
            isFlowController: false,
            appearance: .default
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenLocalizedPricesMetasEmpty() {
        let session = makeSession(includeLocalizedPrices: false)
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: .checkoutSession(session),
            isFlowController: false,
            appearance: .default
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenExchangeRateMetaIsNil() {
        // Create a session with adaptive pricing active and localized prices, but
        // without the exchange rate fields so exchangeRateMeta parses as nil.
        let session = makeSession(includeExchangeRateFields: false)
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: .checkoutSession(session),
            isFlowController: false,
            appearance: .default
        )
        XCTAssertNil(result)
    }

    func testReturnsElementWhenAllConditionsMet() {
        let session = makeAdaptivePricingSession()
        let result = AdaptivePricingSelectorElement.makeIfNeeded(
            intent: .checkoutSession(session),
            isFlowController: false,
            appearance: .default
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.selectedCurrency, "usd")
    }

    // MARK: - Helpers

    private func makeAdaptivePricingSession() -> STPCheckoutSession {
        return makeSession()
    }

    private func makeSession(
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
            "currency": "usd",
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
                "active_presentment_currency": "usd",
                "local_currency_options": [localCurrencyOption],
            ]
        }

        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
