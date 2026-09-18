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

    // MARK: - Available payment methods tests

    func testAvailablePaymentMethodsStoredOnSession() {
        // Given a session listing Link before Apple Pay
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
            merchantId: "merchant.com.example"
        )

        // When the public session is created with the ECE configuration
        let session = makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        // Then it stores the available methods in display order
        let expectedPaymentMethods = StripeAPI.deviceSupportsApplePay() ? ["link", "apple_pay"] : ["link"]
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, expectedPaymentMethods)
    }

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains("apple_pay"))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertEqual(buttons.contains("apple_pay"), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertTrue(buttons.contains("link"))
    }

    func testApplePayButtonHiddenWhenDisplayIsNever() {
        // Given a session with apple_pay and an applePayConfiguration with display set to .never
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
            merchantId: "merchant.com.example",
            display: .never
        )

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains("apple_pay"))
    }

    func testLinkButtonHiddenWhenDisplayIsNever() {
        // Given a session with link and a linkConfiguration with display set to .never
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.linkConfiguration = ExpressCheckoutElement.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains("link"))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(for: session, configuration: configuration)
                .contains(.linkConfiguration)
        )
    }

    func testLinkButtonHiddenWhenShippingAddressIsRequired() {
        // Given a session with Link and ECE configured to require a shipping address
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.shippingAddressRequired = true

        // When
        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)

        // Then Link is hidden because it cannot collect the required shipping address
        XCTAssertFalse(buttons.contains("link"))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(for: session, configuration: configuration)
                .contains(.shippingAddressCollection)
        )
    }

    func testLinkButtonHiddenWhenAutomaticTaxUsesBillingAddress() {
        // Given a session that calculates automatic tax from the billing address
        let session = makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.billing"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session,
            configuration: configuration
        )

        // Then Link is hidden because it cannot update billing-based automatic tax
        XCTAssertTrue(reasons.contains(.automaticTaxAddress))
        XCTAssertFalse(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
                .contains("link")
        )
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given a session whose shipping address is collected outside ECE and used for automatic tax
        let session = makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.shipping"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session,
            configuration: configuration
        )

        // Then shipping-sourced automatic tax alone does not hide Link
        XCTAssertFalse(reasons.contains(.automaticTaxAddress))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
                .contains("link")
        )
    }

    func testLinkButtonHiddenWhenDisabledForAutomaticTaxBilling() {
        // Given Link is disabled because the Checkout Session uses automatic tax billing
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        session.elementsSession.disableLinkForAutomaticTaxBilling = true
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        // When
        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)

        // Then
        XCTAssertFalse(buttons.contains("link"))
    }

    func testApplePayButtonHiddenWhenDisabledOnSession() {
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains("apple_pay"))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons = StripeAPI.deviceSupportsApplePay() ? ["link", "apple_pay"] : ["link"]
        XCTAssertEqual(buttons, expectedButtons)
    }

    // MARK: - Helpers

    private func makeSessionWithWalletTypes(
        _ walletTypes: [String],
        applePayPreference: String? = nil,
        linkUseAttestation: Bool? = nil,
        automaticTaxAddressSource: String? = nil
    ) -> PaymentPagesAPIResponse {
        var elementsSession: [String: Any] = [
            "session_id": "es_test",
            "merchant_country": "US",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "ordered_payment_method_types_and_wallets": walletTypes,
        ]
        if let applePayPreference {
            elementsSession["apple_pay_preference"] = applePayPreference
        }
        if let linkUseAttestation {
            elementsSession["link_settings"] = [
                "link_funding_sources": ["CARD"],
                "link_mobile_use_attestation_endpoints": linkUseAttestation,
            ]
        }
        var session: [String: Any] = ["elements_session": elementsSession]
        if let automaticTaxAddressSource {
            session["tax_context"] = [
                "automatic_tax_enabled": true,
                "automatic_tax_address_source": automaticTaxAddressSource,
            ]
        }
        return CheckoutTestHelpers.makeSession(session)
    }
}
