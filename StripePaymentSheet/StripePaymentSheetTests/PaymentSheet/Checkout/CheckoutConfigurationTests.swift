//
//  CheckoutConfigurationTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutConfigurationTests: XCTestCase {

    func testCheckoutStoresConfiguration() {
        let session = CheckoutTestHelpers.makeOpenSession()
        var config = Checkout.Configuration()
        config.adaptivePricing.allowed = false

        let checkout = Checkout(
            clientSecret: "cs_test_123_secret_abc",
            configuration: config,
            session: session
        )

        XCTAssertFalse(checkout.configuration.adaptivePricing.allowed)
    }

    func testCheckoutDefaultConfiguration() {
        let session = CheckoutTestHelpers.makeOpenSession()
        let checkout = Checkout(
            clientSecret: "cs_test_123_secret_abc",
            session: session
        )

        XCTAssertTrue(checkout.configuration.adaptivePricing.allowed)
    }
}
