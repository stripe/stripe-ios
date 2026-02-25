//
//  CheckoutLoadTests.swift
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

final class CheckoutLoadTests: STPNetworkStubbingTestCase {

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
