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

    // MARK: - resolveButtons tests

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration()

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration()

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration()

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisplayIsNever() {
        // Given a session with apple_pay and an applePayConfiguration with display set to .never
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
            merchantId: "merchant.com.example",
            display: .never
        )

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testLinkButtonHiddenWhenDisplayIsNever() {
        // Given a session with link and a linkConfiguration with display set to .never
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.linkConfiguration = ExpressCheckoutElement.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.link))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(for: session, configuration: configuration)
                .contains(.linkConfiguration)
        )
    }

    func testLinkButtonHiddenWhenShippingAddressIsRequired() {
        // Given a session with Link and ECE configured to require a shipping address
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.shippingAddressRequired = true

        // When
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)

        // Then Link is hidden because it cannot collect the required shipping address
        XCTAssertFalse(buttons.contains(.link))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(for: session, configuration: configuration)
                .contains(.shippingAddressCollection)
        )
    }

    func testLinkButtonHiddenWhenFullBillingAddressIsRequiredAndNativeLinkIsUnavailable() {
        // Given a session that only supports web Link and ECE requires a full billing address
        let session = makeSessionWithWalletTypes(["link"], linkUseAttestation: false).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full

        // When
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(
            for: session,
            configuration: configuration,
            apiClient: STPAPIClient(publishableKey: "pk_test_123")
        )

        // Then Link is hidden because web Link cannot collect the required billing address
        XCTAssertFalse(buttons.contains(.link))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(
                for: session,
                configuration: configuration,
                apiClient: STPAPIClient(publishableKey: "pk_test_123")
            ).contains(.billingDetailsCollection)
        )
    }

    func testLinkButtonShownWhenFullBillingAddressIsRequiredAndNativeLinkIsAvailable() {
        // Given a session that supports native Link and ECE requires a full billing address
        let session = makeSessionWithWalletTypes(["link"], linkUseAttestation: true).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full

        // When
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(
            for: session,
            configuration: configuration,
            apiClient: STPAPIClient(publishableKey: "pk_test_123")
        )

        // Then native Link can collect the required billing address
        XCTAssertTrue(buttons.contains(.link))
    }

    func testLinkButtonHiddenWhenAutomaticTaxUsesBillingAddress() {
        // Given a session that calculates automatic tax from the billing address
        let session = makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.billing"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration()

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session,
            configuration: configuration
        )

        // Then Link is hidden because it cannot update billing-based automatic tax
        XCTAssertTrue(reasons.contains(.automaticTaxAddress))
        XCTAssertFalse(
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given a session whose shipping address is collected outside ECE and used for automatic tax
        let session = makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.shipping"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration()

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session,
            configuration: configuration
        )

        // Then shipping-sourced automatic tax alone does not hide Link
        XCTAssertFalse(reasons.contains(.automaticTaxAddress))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
                .contains(.link)
        )
    }

    func testApplePayButtonHiddenWhenDisabledOnSession() {
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration()
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
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
