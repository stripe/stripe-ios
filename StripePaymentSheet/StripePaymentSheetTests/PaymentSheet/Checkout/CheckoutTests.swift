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
    func testCheckoutInitUsesMerchantProvidedAPIClientInstance() async {
        let apiClient = STPAPIClient(publishableKey: "pk_test_checkout")
        let checkoutSession = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("CheckoutSession")!)!
        stubFlagImages()

        let checkout = await Checkout(
            clientSecret: "cs_test_checkout_secret_123",
            apiResponse: checkoutSession,
            apiClient: apiClient
        )

        XCTAssertTrue(checkout.apiClient === apiClient)
    }

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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
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

    func testDelegateCalledOnPromotionCodeApply() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.applyPromotionCode("SAVE25")

        // Applying the promotion code emits once for the server-backed Checkout session update
        // and once when PaymentElement re-syncs its local payment option.
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertNotNil(delegate.lastSession)
        XCTAssertEqual(promotionCode(in: delegate.lastSession), "SAVE25")
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(recorder.loading, [true, false])
    }

    func testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
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

    func testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
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

    func testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowPromotionCodes: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
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

    func testUpdateQuantity() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            allowAdjustableLineItemQuantity: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertEqual(5050, checkout.session.total?.total.minorUnitsAmount)

        let itemId = try XCTUnwrap(
            checkout.session.lineItems.first?.id,
            "Session should have at least one line item"
        )

        try await checkout.updateQuantity(lineItemId: itemId, quantity: 2)
        XCTAssertEqual(10100, checkout.session.total?.total.minorUnitsAmount)
    }

    func testSelectShippingOption() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            includeShippingOptions: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertEqual(2500, checkout.session.total?.total.minorUnitsAmount)

        let rateId = try XCTUnwrap(
            checkout.session.shippingOptions.last?.id,
            "Session should have at least one shipping option"
        )

        try await checkout.selectShippingOption(rateId)
        XCTAssertEqual(3000, checkout.session.total?.total.minorUnitsAmount)
    }

    func testUpdateBillingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectBillingAddress: true,
            automaticTax: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertNil(checkout.session.billingAddress)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5050)

        // Update the billing address to get tax applied
        try await checkout.updateBillingAddress(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )

        // Address should be stored on the session
        let storedBilling = checkout.session.billingAddress
        XCTAssertNotNil(storedBilling)
        XCTAssertEqual(storedBilling?.name, "Jane Doe")
        XCTAssertEqual(storedBilling?.address.country, "US")
        XCTAssertEqual(storedBilling?.address.line1, "123 Main St")
        XCTAssertEqual(storedBilling?.address.city, "San Francisco")
        XCTAssertEqual(storedBilling?.address.state, "CA")
        XCTAssertEqual(storedBilling?.address.postalCode, "94105")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status?.type, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5486)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            merchantCountry: "us_tax",
            allowAdjustableLineItemQuantity: true,
            collectShippingAddress: true,
            automaticTax: true
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await Checkout(configuration: configuration)

        XCTAssertNil(checkout.session.shippingAddress)

        // Pre-tax price, CA sales tax has not yet been applied
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5050)

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

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.total?.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.total?.total.minorUnitsAmount, 5542)
    }

    func testSelectCurrency() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        var configuration = Checkout.Configuration(clientSecret: checkoutSessionResponse.clientSecret)
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
