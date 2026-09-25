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

    func testCalculateVisibleButtonCount() {
        let testCases: [(buttonCount: Int, maxColumns: Int?, maxRows: Int?, expected: Int)] = [
            (0, 2, 2, 0),
            (5, nil, nil, 5),
            (5, 2, nil, 5),
            (5, nil, 2, 5),
            (5, 2, 2, 4),
            (3, 2, 2, 3),
        ]

        for testCase in testCases {
            XCTAssertEqual(
                ExpressCheckoutElementUIView.calculateVisibleButtonCount(
                    buttonCount: testCase.buttonCount,
                    maxColumns: testCase.maxColumns,
                    maxRows: testCase.maxRows
                ),
                testCase.expected
            )
        }
    }

    func testCalculateColumnCount() {
        let testCases: [(buttonCount: Int, maxRows: Int?, expected: Int)] = [
            (0, 2, 1),
            (5, nil, 1),
            (3, 5, 1),
            (3, 3, 1),
            (4, 2, 2),
            (5, 2, 3),
            (5, 1, 5),
        ]

        for testCase in testCases {
            XCTAssertEqual(
                ExpressCheckoutElementUIView.calculateColumnCount(
                    buttonCount: testCase.buttonCount,
                    maxRows: testCase.maxRows
                ),
                testCase.expected
            )
        }
    }

    func testButtonRowsPreserveOrderAndApplyLimits() {
        let buttons: [ExpressCheckoutElement.PaymentMethod] = [.link, .applePay, .link]
        var layout = ExpressCheckoutElement.Appearance.ButtonLayout()
        layout.maxColumns = 1
        layout.maxRows = 2

        XCTAssertEqual(
            ExpressCheckoutElementUIView.buttonRows(for: buttons, layout: layout),
            [[.link], [.applePay]]
        )
    }

    // MARK: - resolveButtons tests

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisplayIsNever() {
        // Given a session with apple_pay and an applePayConfiguration with display set to .never
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
            merchantId: "merchant.com.example",
            display: .never
        )

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testLinkButtonHiddenWhenDisplayIsNever() {
        // Given a session with link and a linkConfiguration with display set to .never
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
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
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
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

    func testLinkButtonHiddenWhenAutomaticTaxUsesBillingAddress() {
        // Given a session that calculates automatic tax from the billing address
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(
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
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given a session whose shipping address is collected outside ECE and used for automatic tax
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(
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
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonHiddenWhenDisabledForAutomaticTaxBilling() {
        // Given Link is disabled because the Checkout Session uses automatic tax billing
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        session.elementsSession.disableLinkForAutomaticTaxBilling = true
        let configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })

        // When
        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)

        // Then
        XCTAssertFalse(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisabledOnSession() {
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(confirmHandler: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(buttons, expectedButtons)
    }

}
