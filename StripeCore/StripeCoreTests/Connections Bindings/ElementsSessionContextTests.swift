//
//  ElementsSessionContextTests.swift
//  StripeCore
//
//  Created by Stripe on 2026-08-24.
//

@testable @_spi(STP) import StripeCore
import XCTest

final class ElementsSessionContextTests: XCTestCase {
    func testIncentiveEligibilityIntentIDReturnsPaymentIntentID() {
        let context = ElementsSessionContext(
            intentId: .payment("pi_123"),
            eligibleForIncentive: true
        )

        XCTAssertEqual(context.incentiveEligibilityIntentID, "pi_123")
    }

    func testIncentiveEligibilityIntentIDReturnsSetupIntentID() {
        let context = ElementsSessionContext(
            intentId: .setup("seti_123"),
            eligibleForIncentive: true
        )

        XCTAssertEqual(context.incentiveEligibilityIntentID, "seti_123")
    }

    func testIncentiveEligibilityIntentIDIsNilForDeferredIntent() {
        let context = ElementsSessionContext(
            intentId: .deferred("es_123"),
            eligibleForIncentive: true
        )

        XCTAssertNil(context.incentiveEligibilityIntentID)
    }

    func testIncentiveEligibilityIntentIDIsNilWhenIneligible() {
        let context = ElementsSessionContext(
            intentId: .payment("pi_123"),
            eligibleForIncentive: false
        )

        XCTAssertNil(context.incentiveEligibilityIntentID)
    }

    func testIncentiveEligibilityIntentIDIsNilWithoutIntent() {
        let context = ElementsSessionContext(eligibleForIncentive: true)

        XCTAssertNil(context.incentiveEligibilityIntentID)
    }
}
