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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let session = checkout.state.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.mode, .payment)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.paymentStatus, .unpaid)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertFalse(session.livemode)
        XCTAssertNotNil(session.totals)
        XCTAssertFalse(checkout.state.isLoading)
    }

    func testRefreshFetchesLatestServerState() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: apiClient
        )
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        XCTAssertNil(checkout.state.session.appliedPromotionCode)
        XCTAssertEqual(checkout.state.session.totals?.total, 2000)

        _ = try await apiClient.updateCheckoutSession(
            checkoutSessionId: checkoutSessionResponse.id,
            parameters: ["promotion_code": "SAVE25"]
        )

        // The local copy remains stale until refresh() fetches the latest session snapshot.
        XCTAssertNil(checkout.state.session.appliedPromotionCode)
        XCTAssertEqual(checkout.state.session.totals?.total, 2000)

        try await checkout.refresh()

        XCTAssertEqual(checkout.state.session.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(checkout.state.session.totals?.total, 1500)
        XCTAssertFalse(checkout.state.isLoading)
        XCTAssertTrue(delegate.didChangeStateCalled)
        XCTAssertEqual(delegate.lastState?.session.appliedPromotionCode, "SAVE25")
    }

    func testDelegateCalledOnPromotionCodeApply() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        try await checkout.applyPromotionCode("SAVE25")

        XCTAssertTrue(delegate.didChangeStateCalled)
        XCTAssertNotNil(delegate.lastState?.session)
        XCTAssertEqual(delegate.lastState?.session.appliedPromotionCode, "SAVE25")
    }

    func testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertTrue(checkout.state.session.discounts.isEmpty)
        XCTAssertNil(checkout.state.session.appliedPromotionCode)
        XCTAssertEqual(2000, checkout.state.session.totals?.total)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.state.session
        XCTAssertFalse(session.discounts.isEmpty)
        XCTAssertEqual(session.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(1500, session.totals?.total)
    }

    func testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        XCTAssertFalse(checkout.state.session.discounts.isEmpty)
        XCTAssertEqual(checkout.state.session.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(1500, checkout.state.session.totals?.total)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.state.session
        XCTAssertTrue(session.discounts.isEmpty)
        XCTAssertNil(session.appliedPromotionCode)
        XCTAssertEqual(2000, session.totals?.total)
    }

    func testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowAdjustableLineItemQuantity: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertEqual(5050, checkout.state.session.totals?.total)

        let itemId = try XCTUnwrap(
            checkout.state.session.lineItems.first?.id,
            "Session should have at least one line item"
        )

        try await checkout.updateQuantity(with: .init(lineItemId: itemId, quantity: 2))
        XCTAssertEqual(10100, checkout.state.session.totals?.total)
    }

    func testSelectShippingOption() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            includeShippingOptions: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertEqual(2500, checkout.state.session.totals?.total)

        let rateId = try XCTUnwrap(
            checkout.state.session.shippingOptions.last?.id,
            "Session should have at least one shipping option"
        )

        try await checkout.selectShippingOption(rateId)
        XCTAssertEqual(3000, checkout.state.session.totals?.total)
    }

    func testUpdateBillingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectBillingAddress: true,
            automaticTax: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertNil(checkout.state.session.billingAddress)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.state.session.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.state.session.totals?.total, 5050)

        // Update the billing address to get tax applied
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
        let storedBilling = checkout.state.session.billingAddress
        XCTAssertNotNil(storedBilling)
        XCTAssertEqual(storedBilling?.name, "Jane Doe")
        XCTAssertEqual(storedBilling?.address.country, "US")
        XCTAssertEqual(storedBilling?.address.line1, "123 Main St")
        XCTAssertEqual(storedBilling?.address.city, "San Francisco")
        XCTAssertEqual(storedBilling?.address.state, "CA")
        XCTAssertEqual(storedBilling?.address.postalCode, "94105")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.state.session.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.state.session.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.state.session.totals?.total, 5486)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectShippingAddress: true,
            automaticTax: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertNil(checkout.state.session.shippingAddress)

        // Pre-tax price, CA sales tax has not yet been applied
        XCTAssertEqual(checkout.state.session.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.state.session.totals?.total, 5050)

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
        let storedShipping = checkout.state.session.shippingAddress
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.line1, "456 Oak Ave")
        XCTAssertEqual(storedShipping?.address.city, "Los Angeles")
        XCTAssertEqual(storedShipping?.address.state, "CA")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.state.session.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.state.session.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.state.session.totals?.total, 5542)
    }

    func testUpdateTaxId() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            enableTaxIdCollection: true
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.updateTaxId(with: .init(type: "eu_vat", value: "DE123456789"))

        // Updating the tax ID does not change any properties on the payment page init response
        // Nothing to assert on other than it did not fail/throw
        XCTAssertEqual(checkout.state.session.status, .open)
    }

    func testSelectCurrency() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        let checkout = try await Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let initialSession = try XCTUnwrap(checkout.state.session as? STPCheckoutSession)

        // Session loads with the localized currency (EUR for DE)
        XCTAssertEqual(initialSession.currency, "eur")
        XCTAssertTrue(initialSession.adaptivePricingActive)
        XCTAssertNotNil(initialSession.exchangeRateMeta)
        let eurTotal = try XCTUnwrap(initialSession.totals?.total)

        // Switch to USD
        try await checkout.selectCurrency("usd")

        let updatedSession = try XCTUnwrap(checkout.state.session as? STPCheckoutSession)
        XCTAssertEqual(updatedSession.currency, "usd")
        XCTAssertEqual(updatedSession.totals?.total, 2000)
        XCTAssertNotEqual(updatedSession.totals?.total, eurTotal, "USD total should differ from EUR total")
    }
}

// MARK: - Mock Delegate

@MainActor
private class MockCheckoutDelegate: CheckoutDelegate {
    var didChangeStateCalled = false
    var lastState: Checkout.State?

    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State) {
        didChangeStateCalled = true
        lastState = state
    }
}
