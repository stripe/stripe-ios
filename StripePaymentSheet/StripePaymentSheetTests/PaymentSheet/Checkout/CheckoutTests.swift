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
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

@MainActor
final class CheckoutTests: STPNetworkStubbingTestCase {
    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertFalse(checkout.isLoading)
    }

    // TODO(porter): unified mode does not yet support promo codes.
    func disabled_testPromotionCodeApplyEmitsSessionUpdates() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            additionalParameters: ["allow_promotion_codes": true]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.applyPromotionCode("SAVE25")

        // Applying the promotion code emits once for the server-backed Checkout session update
        // and once when PaymentElement re-syncs its local payment option.
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(promotionCode(in: recorder.sessions.last), "SAVE25")
        XCTAssertEqual(recorder.loading, [true, false])
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            additionalParameters: ["allow_promotion_codes": true]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertTrue(checkout.session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: checkout.session))
        XCTAssertEqual(2000, checkout.session.totals.total.minorUnitsAmount)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertFalse(session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: session), "SAVE25")
        XCTAssertEqual(1500, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            additionalParameters: ["allow_promotion_codes": true]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        XCTAssertFalse(checkout.session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: checkout.session), "SAVE25")
        XCTAssertEqual(1500, checkout.session.totals.total.minorUnitsAmount)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertTrue(session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: session))
        XCTAssertEqual(2000, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            additionalParameters: ["allow_promotion_codes": true]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

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

    func testUpdateBillingTaxRegionIfNecessary() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: 5050,
            merchantCountry: "us_tax",
            collectBillingAddress: true,
            automaticTax: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5050)

        // Update the billing tax region to get tax applied
        try await checkout.updateBillingTaxRegionIfNecessary(
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5486)
    }

    func testLoadUnifiedModeCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            useOneTimePrice: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertEqual(session.expectedAmount(), 2000)
        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time price order summary item")
        }
        XCTAssertFalse(oneTimePrice.key.isEmpty)
        XCTAssertNil(oneTimePrice.description)
        XCTAssertEqual(oneTimePrice.items.count, 1)
        let item = try XCTUnwrap(oneTimePrice.items.first)
        XCTAssertFalse(item.key.isEmpty)
        XCTAssertEqual(item.displayName, "Test")
        XCTAssertEqual(item.images, [])
        XCTAssertEqual(item.unitAmount.minorUnitsAmount, 2000)
        XCTAssertEqual(item.unitAmountDecimal?.minorUnitsAmount, 2000)
        XCTAssertNil(item.unitLabel)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertNil(item.adjustableQuantity)
        XCTAssertEqual(oneTimePrice.amountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(oneTimePrice.amountDetails.total.minorUnitsAmount, 2000)
        XCTAssertNil(oneTimePrice.amountDetails.taxAmounts)
        XCTAssertEqual(oneTimePrice.amountDetails.discount.minorUnitsAmount, 0)
        XCTAssertEqual(oneTimePrice.amountDetails.taxInclusive.minorUnitsAmount, 0)
        XCTAssertEqual(oneTimePrice.amountDetails.taxExclusive.minorUnitsAmount, 0)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            additionalParameters: [
                "automatic_tax": ["enabled": true],
                "shipping_address_collection": ["allowed_countries": ["US"]],
            ]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
        XCTAssertNil(checkout.session.tax.taxAmounts)

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(
                country: "US",
                line1: "456 Oak Ave",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90001"
            )
        )

        // Address should be stored on the session
        let storedShipping = checkout.session.shippingAddress
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.line1, "456 Oak Ave")
        XCTAssertEqual(storedShipping?.address.city, "Los Angeles")
        XCTAssertEqual(storedShipping?.address.state, "CA")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2195)
        XCTAssertEqual(checkout.session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(checkout.session.tax.taxAmounts?.first?.amount.minorUnitsAmount, 195)
    }

    func testAdaptivePricingActiveForUnifiedModeCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            customerEmailLocation: "FR"
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.adaptivePricing.allowed = true
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertEqual(checkout.session.currency, "eur")
        XCTAssertTrue(checkout.session.adaptivePricingActive)
        XCTAssertNotNil(checkout.session.exchangeRateMeta)
    }

    func testSelectCurrency() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            customerEmailLocation: "DE"
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.adaptivePricing.allowed = true
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let initialSession = checkout.session

        // Session loads with the localized currency (EUR for DE)
        XCTAssertEqual(initialSession.currency, "eur")
        XCTAssertTrue(initialSession.adaptivePricingActive)
        XCTAssertNotNil(initialSession.exchangeRateMeta)
        let eurTotal = initialSession.totals.total.minorUnitsAmount

        // Switch to USD
        try await checkout.selectCurrency("usd")

        let updatedSession = checkout.session
        XCTAssertEqual(updatedSession.currency, "usd")
        XCTAssertEqual(updatedSession.totals.total.minorUnitsAmount, 2000)
        XCTAssertNotEqual(updatedSession.totals.total.minorUnitsAmount, eurTotal, "USD total should differ from EUR total")
    }

    private func promotionCode(in session: Checkout.Session?) -> String? {
        session?.discountAmounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }
}
