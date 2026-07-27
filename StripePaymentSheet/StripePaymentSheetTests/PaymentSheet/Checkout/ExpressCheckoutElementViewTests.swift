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
            ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    // MARK: - Link WalletVisibility tests

    func testLinkNeverSuppressesLinkWhenSessionAdvertisesIt() {
        // Given a session with link and ECE link visibility set to .never
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.expressCheckoutElement.link = .never

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.link))
    }

    func testLinkAlwaysShowsLinkWhenSessionDoesNotAdvertiseIt() {
        // Given a session without link and ECE link visibility set to .always
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.expressCheckoutElement.link = .always

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    func testLinkConfigurationDisplayNeverSuppressesLink() {
        // Given a session with link and ECE link .automatic, but linkConfiguration.display = .never
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.linkConfiguration = Checkout.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.link))
    }

    func testLinkAlwaysOverridesLinkConfigurationDisplayNever() {
        // Given ECE link .always and linkConfiguration.display = .never, .always wins
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.expressCheckoutElement.link = .always
        configuration.linkConfiguration = Checkout.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    // MARK: - Apple Pay WalletVisibility tests

    func testApplePayNeverSuppressesApplePayWhenSessionAdvertisesIt() {
        // Given a session with apple_pay, applePayConfiguration set, but ECE apple pay .never
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")
        configuration.expressCheckoutElement.applePay = .never

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayAlwaysShowsApplePayWhenSessionDoesNotAdvertiseIt() {
        // Given a session without apple_pay, applePayConfiguration set, ECE apple pay .always
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")
        configuration.expressCheckoutElement.applePay = .always

        // Whether Apple Pay appears depends on device capability
        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testApplePayAlwaysWithoutApplePayConfigurationShowsNoApplePay() {
        // Given ECE apple pay .always but no applePayConfiguration
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.expressCheckoutElement.applePay = .always

        let buttons = ExpressCheckoutElementUIView.expressButtons(from: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
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
