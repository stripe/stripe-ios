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

@MainActor
final class CheckoutTests: STPNetworkStubbingTestCase {

    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertNil(checkout.session)

        try await checkout.load()

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

    func testDelegateCalledOnLoad() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        try await checkout.load()

        XCTAssertTrue(delegate.didUpdateCalled)
        XCTAssertNotNil(delegate.lastSession)
        XCTAssertEqual(delegate.lastSession?.stripeId, checkoutSessionResponse.id)
    }

    func testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()

        XCTAssertNotNil(checkout.session)
        XCTAssertTrue(checkout.session?.discounts.isEmpty ?? false)
        XCTAssertNil(checkout.session?.appliedPromotionCode)
        XCTAssertEqual(2000, checkout.session?.totalSummary?.total)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertNotNil(session)
        XCTAssertFalse(session?.discounts.isEmpty ?? true)
        XCTAssertEqual(session?.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(1500, checkout.session?.totalSummary?.total)
    }

    func testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        XCTAssertFalse(checkout.session?.discounts.isEmpty ?? true)
        XCTAssertEqual(checkout.session?.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(1500, checkout.session?.totalSummary?.total)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertNotNil(session)
        XCTAssertTrue(session?.discounts.isEmpty ?? false)
        XCTAssertNil(session?.appliedPromotionCode)
        XCTAssertEqual(2000, checkout.session?.totalSummary?.total)
    }

    func testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = Checkout(
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

    func testUpdateQuantity() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowAdjustableLineItemQuantity: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertEqual(5050, checkout.session?.totalSummary?.total)

        let lineItemId = await MainActor.run { () -> String? in
            XCTAssertNotNil(checkout.session)
            if let lineItemGroup = checkout.session?.allResponseFields["line_item_group"] as? [AnyHashable: Any],
               let lineItems = lineItemGroup["line_items"] as? [[AnyHashable: Any]],
               let firstItem = lineItems.first,
               let id = firstItem["id"] as? String {
                return id
            }
            return nil
        }

        let itemId = try XCTUnwrap(lineItemId, "Session should have at least one line item")

        try await checkout.updateQuantity(.init(lineItemId: itemId, quantity: 2))
        XCTAssertEqual(10100, checkout.session?.totalSummary?.total)
        XCTAssertNotNil(checkout.session)
    }

    func testSelectShippingOption() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            includeShippingOptions: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertEqual(2500, checkout.session?.totalSummary?.total)

        let shippingRateId = await MainActor.run { () -> String? in
            XCTAssertNotNil(checkout.session)
            if let shippingOptions = checkout.session?.allResponseFields["shipping_options"] as? [[AnyHashable: Any]],
               let firstOption = shippingOptions.last,
               let shippingRate = firstOption["shipping_rate"] as? [AnyHashable: Any],
               let id = shippingRate["id"] as? String {
                return id
            }
            // Fallback: shipping_rate might be a string ID directly
            if let shippingOptions = checkout.session?.allResponseFields["shipping_options"] as? [[AnyHashable: Any]],
               let firstOption = shippingOptions.first,
               let id = firstOption["shipping_rate"] as? String {
                return id
            }
            return nil
        }

        let rateId = try XCTUnwrap(shippingRateId, "Session should have at least one shipping option")

        try await checkout.selectShippingOption(rateId)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(3000, checkout.session?.totalSummary?.total)
    }

    func testUpdateBillingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            collectBillingAddress: true,
            automaticTax: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertNil(checkout.session?.billingAddressOverride)

        // Verify automatic tax is enabled with billing as the address source
        let taxContextBefore = checkout.session?.allResponseFields["tax_context"] as? [String: Any]
        XCTAssertEqual(taxContextBefore?["automatic_tax_enabled"] as? Bool, true)
        XCTAssertEqual(taxContextBefore?["automatic_tax_address_source"] as? String, "session.billing")
        // Before providing an address, tax hasn't been computed yet
        XCTAssertNil(taxContextBefore?["automatic_tax_taxability_reason"] as? String)

        let billingUpdate = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )
        try await checkout.updateBillingAddress(billingUpdate)

        // Address should be stored on the session
        let storedBilling = checkout.session?.billingAddressOverride as? Checkout.AddressUpdate
        XCTAssertNotNil(storedBilling)
        XCTAssertEqual(storedBilling?.name, "Jane Doe")
        XCTAssertEqual(storedBilling?.address.country, "US")
        XCTAssertEqual(storedBilling?.address.postalCode, "94105")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(checkout.session?.status, .open)

        // After providing an address, the server computes tax and updates the tax context
        let taxContextAfter = checkout.session?.allResponseFields["tax_context"] as? [String: Any]
        XCTAssertNotNil(taxContextAfter?["automatic_tax_taxability_reason"] as? String,
                        "Tax taxability reason should be populated after providing an address")
        XCTAssertNotNil(taxContextAfter?["automatic_tax_exempt"] as? String,
                        "Tax exempt status should be populated after providing an address")
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            collectShippingAddress: true,
            automaticTax: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertNil(checkout.session?.shippingAddressOverride)

        // Verify automatic tax is enabled with shipping as the address source
        let taxContextBefore = checkout.session?.allResponseFields["tax_context"] as? [String: Any]
        XCTAssertEqual(taxContextBefore?["automatic_tax_enabled"] as? Bool, true)
        XCTAssertEqual(taxContextBefore?["automatic_tax_address_source"] as? String, "session.shipping")
        // Before providing an address, tax hasn't been computed yet
        XCTAssertNil(taxContextBefore?["automatic_tax_taxability_reason"] as? String)

        let shippingUpdate = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(
                country: "US",
                line1: "456 Oak Ave",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90001"
            )
        )
        try await checkout.updateShippingAddress(shippingUpdate)

        // Address should be stored on the session
        let storedShipping = checkout.session?.shippingAddressOverride as? Checkout.AddressUpdate
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(checkout.session?.status, .open)

        // After providing an address, the server computes tax and updates the tax context
        let taxContextAfter = checkout.session?.allResponseFields["tax_context"] as? [String: Any]
        XCTAssertNotNil(taxContextAfter?["automatic_tax_taxability_reason"] as? String,
                        "Tax taxability reason should be populated after providing an address")
        XCTAssertNotNil(taxContextAfter?["automatic_tax_exempt"] as? String,
                        "Tax exempt status should be populated after providing an address")
    }

    func testDelegateCalledOnPromotionCodeApply() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession(
            allowPromotionCodes: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        checkout.delegate = delegate

        try await checkout.load()

        // Reset delegate state after load
        delegate.didUpdateCalled = false
        delegate.lastSession = nil

        try await checkout.applyPromotionCode("SAVE25")

        XCTAssertTrue(delegate.didUpdateCalled)
        XCTAssertNotNil(delegate.lastSession)
        XCTAssertEqual(delegate.lastSession?.appliedPromotionCode, "SAVE25")
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
