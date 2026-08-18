//
//  Checkout+AdaptivePricingTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

@MainActor
final class Checkout_AdaptivePricingTests: STPNetworkStubbingTestCase {
    func testAdaptivePricingUsesIntegrationAndPresentmentCurrencies() async throws {
        // Given a Checkout Session created in USD and localized to EUR
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            customerEmailLocation: "DE"
        )
        var configuration = Checkout.Configuration(
            clientSecret: checkoutSessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.adaptivePricing.allowed = true
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // When Checkout loads the session
        let checkout = try await Checkout(configuration: configuration)
        let eurSession = checkout.session

        // Then Checkout keeps the USD integration currency and reflects the EUR presentment details and totals
        XCTAssertEqual(eurSession.currency, "usd")
        XCTAssertEqual(eurSession.presentmentDetails?.presentmentCurrency, "eur")
        XCTAssertTrue(eurSession.adaptivePricingActive)
        XCTAssertNotNil(eurSession.exchangeRateMeta)
        let eurTotal = eurSession.totals.total.minorUnitsAmount
        let eurFormattedTotal = eurSession.totals.total.amount

        // When the customer selects the integration currency
        try await checkout.selectCurrency("usd")
        let usdSession = checkout.session

        // Then Checkout keeps the USD integration currency and reflects the updated USD presentment details and totals
        XCTAssertEqual(usdSession.currency, "usd")
        XCTAssertEqual(usdSession.presentmentDetails?.presentmentCurrency, "usd")
        XCTAssertEqual(usdSession.totals.total.minorUnitsAmount, 2000)
        XCTAssertNotEqual(usdSession.totals.total.minorUnitsAmount, eurTotal)
        XCTAssertNotEqual(usdSession.totals.total.amount, eurFormattedTotal)
    }
}
