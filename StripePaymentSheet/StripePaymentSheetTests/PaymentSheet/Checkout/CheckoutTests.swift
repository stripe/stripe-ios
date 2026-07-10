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
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@MainActor
final class CheckoutTests: STPNetworkStubbingTestCase {
    func testCheckoutInitPreservesMerchantProvidedBetas() async {
        let apiClient = STPAPIClient(publishableKey: "pk_test_checkout")
        apiClient.betas = ["merchant_beta=v1"]
        let checkoutSession = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CheckoutSession")!)!
        stubFlagImages()

        let checkout = await Checkout(
            clientSecret: "cs_test_checkout_secret_123",
            apiResponse: checkoutSession,
            apiClient: apiClient
        )

        XCTAssertEqual(checkout.apiClient.betas, apiClient.betas)
    }

    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status?.type, .open)
        XCTAssertEqual(session.status?.paymentStatus, .unpaid)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertFalse(session.livemode)
        XCTAssertNotNil(session.total)
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
        XCTAssertEqual(2000, checkout.session.total?.total.minorUnitsAmount)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertFalse(session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: session), "SAVE25")
        XCTAssertEqual(1500, session.total?.total.minorUnitsAmount)
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
        XCTAssertEqual(1500, checkout.session.total?.total.minorUnitsAmount)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertTrue(session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: session))
        XCTAssertEqual(2000, session.total?.total.minorUnitsAmount)
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
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5050)

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
        XCTAssertEqual(checkout.session.status?.type, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5486)
    }

    func testLoadUnifiedModeCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax"
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status?.type, .open)
        XCTAssertEqual(session.total?.total.minorUnitsAmount, 2000)
        XCTAssertEqual(session.expectedAmount(), 2000)
        XCTAssertEqual(session.lineItems.count, 1)
        XCTAssertEqual(session.lineItems.first?.quantity, 1)
        XCTAssertEqual(session.lineItems.first?.unitAmount?.minorUnitsAmount, 2000)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            additionalParameters: [
                "checkout_items": [
                    [
                        "type": "one_time_price_item",
                        "one_time_price_item": [
                            "price": "price_1TxraFK8p6Sx2i8aHUda5nwK",
                            "quantity": 1,
                        ],
                    ],
                ],
                "automatic_tax": ["enabled": true],
                "shipping_address_collection": ["allowed_countries": ["US"]],
            ]
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 2000)
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
        XCTAssertEqual(checkout.session.status?.type, .open)

        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 2195)
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
        let eurTotal = try XCTUnwrap(initialSession.total?.total.minorUnitsAmount)

        // Switch to USD
        try await checkout.selectCurrency("usd")

        let updatedSession = checkout.session
        XCTAssertEqual(updatedSession.currency, "usd")
        XCTAssertEqual(updatedSession.total?.total.minorUnitsAmount, 2000)
        XCTAssertNotEqual(updatedSession.total?.total.minorUnitsAmount, eurTotal, "USD total should differ from EUR total")
    }

    private func promotionCode(in session: Checkout.Session?) -> String? {
        session?.discountAmounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }

    private func stubFlagImages() {
        let imageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aK6cAAAAASUVORK5CYII=")!
        stub { request in
            request.url?.host == "img.stripecdn.com"
        } response: { _ in
            HTTPStubsResponse(data: imageData, statusCode: 200, headers: ["Content-Type": "image/png"])
        }
    }
}
