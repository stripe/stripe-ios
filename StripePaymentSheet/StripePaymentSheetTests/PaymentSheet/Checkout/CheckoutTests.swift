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
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        XCTAssertNil(checkout.session)

        try await checkout.load()

        let session = checkout.session
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.id, checkoutSessionResponse.id)
        XCTAssertEqual(session?.mode, .payment)
        XCTAssertEqual(session?.status, .open)
        XCTAssertEqual(session?.paymentStatus, .unpaid)
        XCTAssertEqual(session?.currency, "usd")
        XCTAssertFalse(session?.livemode ?? true)
        XCTAssertNotNil(session?.totals)
    }

    func testDelegateCalledOnLoad() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        try await checkout.load()

        XCTAssertTrue(delegate.didUpdateCalled)
        XCTAssertNotNil(delegate.lastSession)
        XCTAssertEqual(delegate.lastSession?.id, checkoutSessionResponse.id)
    }

    func testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
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
        XCTAssertEqual(2000, checkout.session?.totals?.total)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertNotNil(session)
        XCTAssertFalse(session?.discounts.isEmpty ?? true)
        XCTAssertEqual(session?.appliedPromotionCode, "SAVE25")
        XCTAssertEqual(1500, session?.totals?.total)
    }

    func testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
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
        XCTAssertEqual(1500, checkout.session?.totals?.total)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertNotNil(session)
        XCTAssertTrue(session?.discounts.isEmpty ?? false)
        XCTAssertNil(session?.appliedPromotionCode)
        XCTAssertEqual(2000, session?.totals?.total)
    }

    func testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowAdjustableLineItemQuantity: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertEqual(5050, checkout.session?.totals?.total)

        let itemId = try XCTUnwrap(
            checkout.session?.lineItems.first?.id,
            "Session should have at least one line item"
        )

        try await checkout.updateQuantity(with: .init(lineItemId: itemId, quantity: 2))
        XCTAssertEqual(10100, checkout.session?.totals?.total)
        XCTAssertNotNil(checkout.session)
    }

    func testSelectShippingOption() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            includeShippingOptions: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertEqual(2500, checkout.session?.totals?.total)

        let rateId = try XCTUnwrap(
            checkout.session?.shippingOptions.last?.id,
            "Session should have at least one shipping option"
        )

        try await checkout.selectShippingOption(rateId)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(3000, checkout.session?.totals?.total)
    }

    func testUpdateBillingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectBillingAddress: true,
            automaticTax: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertNil(checkout.session?.billingAddress)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.session?.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.session?.totals?.total, 5050)

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
        let storedBilling = checkout.session?.billingAddress
        XCTAssertNotNil(storedBilling)
        XCTAssertEqual(storedBilling?.name, "Jane Doe")
        XCTAssertEqual(storedBilling?.address.country, "US")
        XCTAssertEqual(storedBilling?.address.line1, "123 Main St")
        XCTAssertEqual(storedBilling?.address.city, "San Francisco")
        XCTAssertEqual(storedBilling?.address.state, "CA")
        XCTAssertEqual(storedBilling?.address.postalCode, "94105")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(checkout.session?.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session?.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.session?.totals?.total, 5486)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectShippingAddress: true,
            automaticTax: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertNil(checkout.session?.shippingAddress)

        // Pre-tax price, CA sales tax has not yet been applied
        XCTAssertEqual(checkout.session?.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.session?.totals?.total, 5050)

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
        let storedShipping = checkout.session?.shippingAddress
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.line1, "456 Oak Ave")
        XCTAssertEqual(storedShipping?.address.city, "Los Angeles")
        XCTAssertEqual(storedShipping?.address.state, "CA")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(checkout.session?.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session?.totals?.subtotal, 5050)
        XCTAssertEqual(checkout.session?.totals?.total, 5542)
    }

    func testUpdateTaxId() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            enableTaxIdCollection: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        XCTAssertNotNil(checkout.session)

        try await checkout.updateTaxId(with: .init(type: "eu_vat", value: "DE123456789"))

        // Updating the tax ID does not change any properties on the payment page init response
        // Nothing to assert on other than it did not fail/throw
        XCTAssertNotNil(checkout.session)
        XCTAssertEqual(checkout.session?.status, .open)
    }

    func testSelectCurrency() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        try await checkout.load()
        let initialSession = try XCTUnwrap(checkout.session as? STPCheckoutSession)
        XCTAssertEqual(initialSession.currency, "eur")
        XCTAssertEqual(initialSession.totals?.total, 1799)
        XCTAssertTrue(initialSession.adaptivePricingActive)
        XCTAssertEqual(initialSession.exchangeRateMeta?.buyCurrency, "eur")
        XCTAssertEqual(initialSession.exchangeRateMeta?.sellCurrency, "usd")
        XCTAssertEqual(initialSession.exchangeRateMeta?.integrationCurrency, "usd")
        XCTAssertEqual(initialSession.exchangeRateMeta?.localizedCurrency, "eur")
        XCTAssertEqual(initialSession.exchangeRateMeta?.exchangeRate, "0.8995")
        XCTAssertEqual(initialSession.exchangeRateMeta?.conversionMarkupBps, 400)
        XCTAssertEqual(initialSession.localizedPricesMetas.count, 2)
        XCTAssertEqual(initialSession.localizedPricesMetas[0].currency, "eur")
        XCTAssertEqual(initialSession.localizedPricesMetas[0].total, 1799)
        XCTAssertEqual(initialSession.localizedPricesMetas[1].currency, "usd")
        XCTAssertEqual(initialSession.localizedPricesMetas[1].total, 2000)

        try await checkout.selectCurrency("usd")

        let updatedSession = try XCTUnwrap(checkout.session as? STPCheckoutSession)
        XCTAssertEqual(updatedSession.currency, "usd")
        XCTAssertEqual(updatedSession.totals?.total, 2000)
        XCTAssertTrue(updatedSession.adaptivePricingActive)
        XCTAssertEqual(updatedSession.exchangeRateMeta?.buyCurrency, "eur")
        XCTAssertEqual(updatedSession.exchangeRateMeta?.sellCurrency, "usd")
        XCTAssertEqual(updatedSession.exchangeRateMeta?.integrationCurrency, "usd")
        XCTAssertEqual(updatedSession.exchangeRateMeta?.localizedCurrency, "eur")
        XCTAssertEqual(updatedSession.exchangeRateMeta?.exchangeRate, "0.8995")
        XCTAssertEqual(updatedSession.exchangeRateMeta?.conversionMarkupBps, 400)
        XCTAssertEqual(updatedSession.localizedPricesMetas.count, 2)
        XCTAssertEqual(updatedSession.localizedPricesMetas[0].currency, "eur")
        XCTAssertEqual(updatedSession.localizedPricesMetas[0].total, 1799)
        XCTAssertEqual(updatedSession.localizedPricesMetas[1].currency, "usd")
        XCTAssertEqual(updatedSession.localizedPricesMetas[1].total, 2000)
    }

    func testDelegateCalledOnPromotionCodeApply() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        let checkout = Checkout(
            clientSecret: checkoutSessionResponse.clientSecret,
            apiClient: STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        )

        let delegate = MockCheckoutDelegate()
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
    var lastSession: (Checkout.Session)?

    func checkout(_ checkout: Checkout, didUpdate session: Checkout.Session) {
        didUpdateCalled = true
        lastSession = session
    }
}
