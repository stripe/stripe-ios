//
//  CheckoutTests.swift
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

final class CheckoutTests: STPNetworkStubbingTestCase {

    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        await MainActor.run { XCTAssertNil(checkout.session) }

        try await checkout.load()

        await MainActor.run {
            let session = checkout.session
            XCTAssertNotNil(session)
            XCTAssertEqual(session?.stripeId, checkoutSessionResponse.id)
            XCTAssertEqual(session?.mode, .payment)
            XCTAssertEqual(session?.status, .open)
            XCTAssertEqual(session?.paymentStatus, .unpaid)
            XCTAssertEqual(session?.currency, "usd")
            XCTAssertFalse(session?.livemode ?? true)
            XCTAssertTrue(session?.paymentMethodTypes.contains(.card) ?? false)
            XCTAssertNotNil(session?.totalSummary)
        }
    }

    func testDelegateCalledOnLoad() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let checkout = await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = await MockCheckoutDelegate()
        await MainActor.run {
            checkout.delegate = delegate
        }

        try await checkout.load()

        await MainActor.run {
            XCTAssertTrue(delegate.didUpdateCalled)
            XCTAssertNotNil(delegate.lastSession)
            XCTAssertEqual(delegate.lastSession?.stripeId, checkoutSessionResponse.id)
        }
    }

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
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError, got \(error)")
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
