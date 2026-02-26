//
//  CheckoutPromotionCodeTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

final class CheckoutPromotionCodeTests: STPNetworkStubbingTestCase {

    // MARK: - Unit Tests (no network)

    func testApplyPromotionCodeRequiresOpenSession() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotOpen
        await MainActor.run { XCTAssertNil(checkout.session) }

        do {
            try await checkout.applyPromotionCode("SAVE25")
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testRemovePromotionCodeRequiresOpenSession() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotOpen
        await MainActor.run { XCTAssertNil(checkout.session) }

        do {
            try await checkout.removePromotionCode()
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    // MARK: - Network-Recorded Integration Tests

    func testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()

        await MainActor.run {
            XCTAssertNotNil(checkout.session)
            XCTAssertTrue(checkout.session?.discounts.isEmpty ?? false)
            XCTAssertNil(checkout.session?.appliedPromotionCode)
        }

        try await checkout.applyPromotionCode("SAVE25")

        await MainActor.run {
            let session = checkout.session
            XCTAssertNotNil(session)
            XCTAssertFalse(session?.discounts.isEmpty ?? true)
            XCTAssertEqual(session?.appliedPromotionCode, "SAVE25")
        }
    }

    func testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        await MainActor.run {
            XCTAssertFalse(checkout.session?.discounts.isEmpty ?? true)
            XCTAssertEqual(checkout.session?.appliedPromotionCode, "SAVE25")
        }

        // Then remove
        try await checkout.removePromotionCode()
        await MainActor.run {
            let session = checkout.session
            XCTAssertNotNil(session)
            XCTAssertTrue(session?.discounts.isEmpty ?? false)
            XCTAssertNil(session?.appliedPromotionCode)
        }
    }

    func testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()

        do {
            try await checkout.applyPromotionCode("BOGUS_CODE_123")
            XCTFail("Expected CheckoutError.invalidPromotionCode")
        } catch let error as CheckoutError {
            guard case .invalidPromotionCode = error else {
                XCTFail("Expected .invalidPromotionCode, got \(error)")
                return
            }
        }
    }

    func testDelegateCalledOnPromotionCodeApply() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = await MockCheckoutDelegate()
        await MainActor.run {
            checkout.delegate = delegate
        }

        try await checkout.load()

        // Reset delegate state after load
        await MainActor.run {
            delegate.didUpdateCalled = false
            delegate.lastSession = nil
        }

        try await checkout.applyPromotionCode("SAVE25")

        await MainActor.run {
            XCTAssertTrue(delegate.didUpdateCalled)
            XCTAssertNotNil(delegate.lastSession)
            XCTAssertEqual(delegate.lastSession?.appliedPromotionCode, "SAVE25")
        }
    }
}

// MARK: - Mock Delegate

@MainActor
private class MockCheckoutDelegate: CheckoutDelegate {
    var didUpdateCalled = false
    var lastSession: STPCheckoutSession?

    func checkout(_ checkout: Checkout, didUpdate session: STPCheckoutSession) {
        didUpdateCalled = true
        lastSession = session
    }
}
