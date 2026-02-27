//
//  CheckoutUnitTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

final class CheckoutUnitTests: XCTestCase {

    func testInitialStateIsNil() async {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")
        await MainActor.run {
            XCTAssertNil(checkout.session)
        }
    }

    func testExtractSessionId() {
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_test_abc123_secret_xyz789"),
            "cs_test_abc123"
        )
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_live_def456_secret_uvw012"),
            "cs_live_def456"
        )
        // No _secret_ separator returns original
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_test_nosecret"),
            "cs_test_nosecret"
        )
    }

    func testApplyPromotionCodeRequiresOpenSession() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

        do {
            try await checkout.applyPromotionCode("SAVE25")
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    func testRemovePromotionCodeRequiresOpenSession() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

        do {
            try await checkout.removePromotionCode()
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }
}
