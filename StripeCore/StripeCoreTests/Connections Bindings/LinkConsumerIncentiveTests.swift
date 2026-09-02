//
//  LinkConsumerIncentiveTests.swift
//  StripeCoreTests
//
//  Created by Stripe on 2026-08-25.
//

@testable @_spi(STP) import StripeCore
import XCTest

final class LinkConsumerIncentiveTests: XCTestCase {
    func testDecodesCompleteVariableIncentive() throws {
        // Given a signed, session-specific variable incentive
        let response: [AnyHashable: Any] = [
            "incentive_campaign": "instant_debits_subscription",
            "incentive_params": [
                "amount_flat": 2_000,
                "amount_percent": 12.5,
                "currency": "usd",
                "minimum_payment_amount": 2_000,
                "payment_method": "link_instant_debits",
            ],
            "incentive_display_text": "$20",
            "incentive_params_signature": "signed_params_123",
            "valid_for_session": true,
        ]

        // When decoding the offer
        let incentive = try XCTUnwrap(LinkConsumerIncentive.decodedObject(fromAPIResponse: response))

        // Then every field needed by native signup and the hosted flow is preserved
        XCTAssertEqual(incentive.incentiveCampaign, "instant_debits_subscription")
        XCTAssertEqual(incentive.incentiveParams.paymentMethod, "link_instant_debits")
        XCTAssertEqual(incentive.incentiveParams.amountFlat, 2_000)
        XCTAssertEqual(incentive.incentiveParams.amountPercent, 12.5)
        XCTAssertEqual(incentive.incentiveParams.currency, "usd")
        XCTAssertEqual(incentive.incentiveParams.minimumPaymentAmount, 2_000)
        XCTAssertEqual(incentive.incentiveDisplayText, "$20")
        XCTAssertEqual(incentive.incentiveParamsSignature, "signed_params_123")
        XCTAssertEqual(incentive.validForSession, true)
    }

    func testIncentiveEligibilityIntentIDOnlyReturnsConcreteIntentIDs() {
        XCTAssertEqual(
            ElementsSessionContext(intentId: .payment("pi_123"), eligibleForIncentive: true).incentiveEligibilityIntentID,
            "pi_123"
        )
        XCTAssertEqual(
            ElementsSessionContext(intentId: .setup("seti_123"), eligibleForIncentive: true).incentiveEligibilityIntentID,
            "seti_123"
        )
        XCTAssertNil(
            ElementsSessionContext(intentId: .deferred("elements_session_123"), eligibleForIncentive: true).incentiveEligibilityIntentID
        )
        XCTAssertNil(
            ElementsSessionContext(intentId: .checkout("cs_123"), eligibleForIncentive: true).incentiveEligibilityIntentID
        )
        XCTAssertNil(
            ElementsSessionContext(intentId: .payment("pi_123"), eligibleForIncentive: false).incentiveEligibilityIntentID
        )
    }
}
