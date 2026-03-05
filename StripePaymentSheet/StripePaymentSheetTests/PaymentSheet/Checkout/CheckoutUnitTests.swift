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

@MainActor
final class CheckoutUnitTests: XCTestCase {

    func testInitialStateIsNil() {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)
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
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

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
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

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

    func testUpdateQuantityRequiresOpenSession() async throws {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

        do {
            try await checkout.updateQuantity(with: .init(lineItemId: "li_123", quantity: 2))
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    func testSelectShippingOptionRequiresOpenSession() async throws {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

        do {
            try await checkout.selectShippingOption("shr_123")
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    func testUpdateBillingAddressRequiresOpenSession() async throws {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

        do {
            try await checkout.updateBillingAddress(
                .init(name: "Jane Doe", address: .init(country: "US"))
            )
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    func testUpdateShippingAddressRequiresOpenSession() async throws {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

        do {
            try await checkout.updateShippingAddress(
                .init(name: "Jane Doe", address: .init(country: "US"))
            )
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    func testUpdateTaxIdRequiresOpenSession() async throws {
        let checkout = Checkout(clientSecret: "cs_test_fake_secret_abc")
        XCTAssertNil(checkout.session)

        do {
            try await checkout.updateTaxId(with: .init(type: "eu_vat", value: "DE123456789"))
            XCTFail("Expected CheckoutError.sessionNotLoaded")
        } catch let error as CheckoutError {
            guard case .sessionNotLoaded = error else {
                XCTFail("Expected .sessionNotLoaded, got \(error)")
                return
            }
        }
    }

    // MARK: - Address Override Tests

    func testUpdateBillingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        let update = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )
        try await checkout.updateBillingAddress(update)

        let stored = checkout.session?.billingAddressOverride
        XCTAssertEqual(stored?.name, "Jane Doe")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertTrue(delegate.didUpdateCalled)
    }

    func testUpdateShippingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        let update = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )
        try await checkout.updateShippingAddress(update)

        let stored = checkout.session?.shippingAddressOverride
        XCTAssertEqual(stored?.name, "John Smith")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertTrue(delegate.didUpdateCalled)
    }

    // MARK: - Helpers

    private static func makeOpenSessionJSON() -> [AnyHashable: Any] {
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

    private static func makeOpenSession() -> STPCheckoutSession {
        STPCheckoutSession.decodedObject(fromAPIResponse: makeOpenSessionJSON())!
    }

    private func makeCheckoutWithOpenSession() -> Checkout {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = Self.makeOpenSession()
        checkout.updateSession(session)
        return checkout
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
