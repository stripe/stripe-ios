//
//  ExpressCheckoutElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class ExpressCheckoutElementViewTests: XCTestCase {

    // MARK: - expressButtons tests

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")

        XCTAssertEqual(
            Checkout.ExpressCheckoutElementView.expressButtons(from: session, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")

        let buttons = Checkout.ExpressCheckoutElementView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = Checkout.ExpressCheckoutElementView.expressButtons(from: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")

        let buttons = Checkout.ExpressCheckoutElementView.expressButtons(from: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    // MARK: - isExpressCheckoutElementAvailable tests

    func testIsExpressCheckoutElementAvailableFalseWithNoWalletTypes() {
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        XCTAssertFalse(session.isExpressCheckoutElementAvailable)
    }

    func testIsExpressCheckoutElementAvailableTrueWithWalletTypes() {
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        XCTAssertTrue(session.isExpressCheckoutElementAvailable)
    }

    // MARK: - Helpers

    private func makeSessionWithWalletTypes(_ walletTypes: [String]) -> PaymentPagesAPIResponse {
        let elementsSession: [String: Any] = [
            "session_id": "es_test",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "ordered_payment_method_types_and_wallets": walletTypes,
        ]
        return CheckoutTestHelpers.makeSession(["elements_session": elementsSession])
    }
}
