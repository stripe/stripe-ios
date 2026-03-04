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

    func testUpdateQuantityRequiresOpenSession() async throws {
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

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
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

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
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

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
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

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
        let checkout = await Checkout(clientSecret: "cs_test_fake_secret_abc")

        // Session is nil (not loaded), should throw sessionNotLoaded
        await MainActor.run { XCTAssertNil(checkout.session) }

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

    func testClearBillingAddress() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        await MainActor.run {
            checkout.session?.billingAddressOverride = Checkout.AddressUpdate(
                name: "Jane",
                address: .init(country: "US")
            )
        }

        try await checkout.updateBillingAddress(nil)

        await MainActor.run {
            XCTAssertNil(checkout.session?.billingAddressOverride)
        }
    }

    func testClearShippingAddress() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        await MainActor.run {
            checkout.session?.shippingAddressOverride = Checkout.AddressUpdate(
                name: "Jane",
                address: .init(country: "US")
            )
        }

        try await checkout.updateShippingAddress(nil)

        await MainActor.run {
            XCTAssertNil(checkout.session?.shippingAddressOverride)
        }
    }

    func testUpdateBillingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = await MainActor.run { MockCheckoutDelegate() }
        await MainActor.run { checkout.delegate = delegate }

        let update = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )
        try await checkout.updateBillingAddress(update)

        await MainActor.run {
            let stored = checkout.session?.billingAddressOverride as? Checkout.AddressUpdate
            XCTAssertEqual(stored?.name, "Jane Doe")
            XCTAssertEqual(stored?.address.country, "US")
            XCTAssertTrue(delegate.didUpdateCalled)
        }
    }

    func testUpdateShippingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = await MainActor.run { MockCheckoutDelegate() }
        await MainActor.run { checkout.delegate = delegate }

        let update = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )
        try await checkout.updateShippingAddress(update)

        await MainActor.run {
            let stored = checkout.session?.shippingAddressOverride as? Checkout.AddressUpdate
            XCTAssertEqual(stored?.name, "John Smith")
            XCTAssertEqual(stored?.address.country, "US")
            XCTAssertTrue(delegate.didUpdateCalled)
        }
    }

    // MARK: - Address Merging Tests

    func testApplyAddressOverrides_billingFillsEmptyFields() async {
        let session = await MainActor.run { Self.makeOpenSession() }
        session.billingAddressOverride = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(config.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(config.defaultBillingDetails.address.line1, "123 Main St")
        XCTAssertEqual(config.defaultBillingDetails.address.city, "SF")
        XCTAssertEqual(config.defaultBillingDetails.address.state, "CA")
        XCTAssertEqual(config.defaultBillingDetails.address.postalCode, "94105")
    }

    func testApplyAddressOverrides_billingConfigTakesPrecedence() async {
        let session = await MainActor.run { Self.makeOpenSession() }
        session.billingAddressOverride = Checkout.AddressUpdate(
            name: "Override Name",
            address: .init(country: "GB", line1: "Override Line1")
        )

        var config = PaymentSheet.Configuration()
        config.defaultBillingDetails.name = "Config Name"
        config.defaultBillingDetails.address.country = "US"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.name, "Config Name")
        XCTAssertEqual(config.defaultBillingDetails.address.country, "US")
        // line1 was empty in config, so override fills it
        XCTAssertEqual(config.defaultBillingDetails.address.line1, "Override Line1")
    }

    func testApplyAddressOverrides_shippingApplied() async {
        let session = await MainActor.run { Self.makeOpenSession() }
        session.shippingAddressOverride = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        var config = PaymentSheet.Configuration()
        XCTAssertNil(config.shippingDetails())
        session.applyAddressOverrides(to: &config)

        let details = config.shippingDetails()
        XCTAssertNotNil(details)
        XCTAssertEqual(details?.name, "John Smith")
        XCTAssertEqual(details?.address.country, "US")
        XCTAssertEqual(details?.address.line1, "456 Oak Ave")
        XCTAssertEqual(details?.address.city, "LA")
        XCTAssertEqual(details?.address.state, "CA")
        XCTAssertEqual(details?.address.postalCode, "90001")
    }

    func testApplyAddressOverrides_shippingNotOverriddenWhenConfigHasShipping() async {
        let session = await MainActor.run { Self.makeOpenSession() }
        session.shippingAddressOverride = Checkout.AddressUpdate(
            name: "Override",
            address: .init(country: "GB")
        )

        var config = PaymentSheet.Configuration()
        let existingDetails = AddressViewController.AddressDetails(
            address: .init(country: "US", line1: "Existing"),
            name: "Existing Name",
            phone: nil
        )
        config.shippingDetails = { existingDetails }
        session.applyAddressOverrides(to: &config)

        let details = config.shippingDetails()
        XCTAssertEqual(details?.name, "Existing Name")
        XCTAssertEqual(details?.address.country, "US")
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

    @MainActor
    private static func makeOpenSession() -> STPCheckoutSession {
        STPCheckoutSession.decodedObject(fromAPIResponse: makeOpenSessionJSON())!
    }

    @MainActor
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
