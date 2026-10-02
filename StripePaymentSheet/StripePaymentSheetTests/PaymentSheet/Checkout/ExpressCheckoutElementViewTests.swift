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

    func testButtonRowsPreserveOrderAndApplyLimits() {
        let buttons: [ExpressCheckoutElement.PaymentMethod] = [.link, .applePay, .link, .applePay, .link]
        var layout = ExpressCheckoutElement.Configuration.Appearance.ButtonLayout()
        layout.maxColumns = 2
        layout.maxRows = 2

        XCTAssertEqual(
            ExpressCheckoutElementUIView.buttonRows(for: buttons, layout: layout),
            [[.link, .applePay], [.link, .applePay]]
        )
    }

    func testButtonRowsUsesFewestColumnsNeededToRespectMaxRows() {
        let buttons: [ExpressCheckoutElement.PaymentMethod] = [.link, .applePay, .link, .applePay, .link]
        var layout = ExpressCheckoutElement.Configuration.Appearance.ButtonLayout()
        layout.maxRows = 2

        XCTAssertEqual(
            ExpressCheckoutElementUIView.buttonRows(for: buttons, layout: layout),
            [[.link, .applePay, .link], [.applePay, .link]]
        )
    }

    func testButtonRowsPrefersOneColumnWhenOnlyMaxColumnsIsSet() {
        let buttons: [ExpressCheckoutElement.PaymentMethod] = [.link, .applePay]
        var layout = ExpressCheckoutElement.Configuration.Appearance.ButtonLayout()
        layout.maxColumns = 2

        XCTAssertEqual(
            ExpressCheckoutElementUIView.buttonRows(for: buttons, layout: layout),
            [[.link], [.applePay]]
        )
    }

    // MARK: - Available payment methods tests

    func testAvailablePaymentMethodsStoredOnSession() {
        // Given a session listing Link before Apple Pay
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example"
        )

        // When the public session is created with the ECE configuration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        // Then it stores the available methods in display order
        let expectedPaymentMethods: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, expectedPaymentMethods)
    }

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisplayIsNever() {
        // Given a session with apple_pay and an applePayConfiguration with display set to .never
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example",
            display: .never
        )

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testLinkButtonHiddenWhenDisplayIsNever() {
        // Given a session with link and a linkConfiguration with display set to .never
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.linkConfiguration = ExpressCheckoutElement.Configuration.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.link))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasons(for: session.elementsSession, configuration: configuration)
                .contains(.linkConfiguration)
        )
    }

    func testLinkButtonHiddenWhenAutomaticTaxUsesBillingAddress() {
        // Given a session that calculates automatic tax from the billing address
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.billing"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session.elementsSession,
            configuration: configuration
        )

        // Then Link is hidden because it cannot update billing-based automatic tax
        XCTAssertTrue(reasons.contains(.automaticTaxAddress))
        XCTAssertFalse(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given a session whose shipping address is collected outside ECE and used for automatic tax
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.shipping"
        ).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session.elementsSession,
            configuration: configuration
        )

        // Then shipping-sourced automatic tax alone does not hide Link
        XCTAssertFalse(reasons.contains(.automaticTaxAddress))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonHiddenWhenDisabledForAutomaticTaxBilling() {
        // Given Link is disabled because the Checkout Session uses automatic tax billing
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        session.elementsSession.disableLinkForAutomaticTaxBilling = true
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        // When
        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)

        // Then
        XCTAssertFalse(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisabledOnSession() {
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethods(for: session.elementsSession, configuration: configuration)

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(buttons, expectedButtons)
    }

    func testPaymentMethodOrder() {
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example"
        )
        let elementsSession = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay", "link"]).makePublicSession().elementsSession

        func availablePaymentMethods(order: [String]?) -> [ExpressCheckoutElement.PaymentMethod] {
            configuration.paymentMethodOrder = order
            return ExpressCheckoutElementUtilities.availablePaymentMethods(
                for: elementsSession,
                configuration: configuration
            )
        }

        guard StripeAPI.deviceSupportsApplePay() else {
            XCTAssertEqual(availablePaymentMethods(order: ["apple_pay", "link"]), [.link])
            return
        }

        // Then configured methods are moved to the front
        XCTAssertEqual(availablePaymentMethods(order: ["link"]), [.link, .applePay])
        // ...and matching is case-insensitive
        XCTAssertEqual(availablePaymentMethods(order: ["LINK"]), [.link, .applePay])
        // ...and invalid and duplicate entries are ignored
        XCTAssertEqual(
            availablePaymentMethods(order: ["unknown", "link", "link"]),
            [.link, .applePay]
        )
        // ...and nil or empty ordering preserves server order
        XCTAssertEqual(availablePaymentMethods(order: nil), [.applePay, .link])
        XCTAssertEqual(availablePaymentMethods(order: []), [.applePay, .link])
    }

    func testAvailablePaymentMethodsStoredOnSessionApplyPaymentMethodOrder() {
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example"
        )
        configuration.paymentMethodOrder = ["link", "apple_pay"]

        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay", "link"]).makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        let expectedPaymentMethods: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, expectedPaymentMethods)
    }
}
