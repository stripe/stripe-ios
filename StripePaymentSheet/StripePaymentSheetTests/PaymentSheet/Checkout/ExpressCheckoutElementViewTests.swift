//
//  ExpressCheckoutElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class ExpressCheckoutElementViewTests: XCTestCase {

    func testAutomaticApplePayButtonUpdatesWithInterfaceStyle() throws {
        // Given an automatic Apple Pay button in light mode
        let view = makeApplePayView(theme: .automatic)
        let window = UIWindow(frame: view.bounds)
        window.addSubview(view)
        window.isHidden = false
        defer { window.isHidden = true }
        view.overrideUserInterfaceStyle = .light
        let lightButton = try applePayButton(in: view)
        let lightImage = render(lightButton)
        XCTAssertEqual(lightImage.pngData(), render(try applePayButton(in: makeApplePayView(theme: .dark))).pngData())

        // When the interface changes to dark mode
        view.overrideUserInterfaceStyle = .dark
        let darkButton = try applePayButton(in: view)
        let darkImage = render(darkButton)

        // Then the button is recreated in white and changes back to black in light mode
        XCTAssertFalse(lightButton === darkButton)
        XCTAssertNotEqual(lightImage.pngData(), darkImage.pngData())
        XCTAssertEqual(darkImage.pngData(), render(try applePayButton(in: makeApplePayView(theme: .light))).pngData())
        view.overrideUserInterfaceStyle = .light
        XCTAssertEqual(render(try applePayButton(in: view)).pngData(), lightImage.pngData())
    }

    func testExplicitApplePayButtonThemesDoNotChangeWithInterfaceStyle() throws {
        let themes: [ExpressCheckoutElement.Configuration.Appearance.ButtonTheme] = [.light, .dark]
        for theme in themes {
            // Given an explicit theme in light mode
            let view = makeApplePayView(theme: theme)
            let window = UIWindow(frame: view.bounds)
            window.addSubview(view)
            window.isHidden = false
            defer { window.isHidden = true }
            view.overrideUserInterfaceStyle = .light
            let button = try applePayButton(in: view)
            let image = render(button)

            // When the interface changes to dark mode
            view.overrideUserInterfaceStyle = .dark

            // Then the same button keeps its configured color
            XCTAssertTrue(button === (try applePayButton(in: view)))
            XCTAssertEqual(render(button).pngData(), image.pngData())
        }
    }

    private func makeApplePayView(theme: ExpressCheckoutElement.Configuration.Appearance.ButtonTheme) -> ExpressCheckoutElementUIView {
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
        configuration.appearance.buttonTheme = theme
        configuration.appearance.cornerRadius = 6
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let view = ExpressCheckoutElementUIView(
            session: session,
            configuration: configuration,
            delegate: FakeExpressCheckoutElementDelegate()
        )
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 44)
        view.update(with: session, buttons: [.applePay])
        return view
    }

    private func applePayButton(in view: ExpressCheckoutElementUIView) throws -> PKPaymentButton {
        if #available(iOS 17.0, *) {
            view.updateTraitsIfNeeded()
        }
        view.layoutIfNeeded()
        let stack = try XCTUnwrap(view.subviews.first as? UIStackView)
        let row = try XCTUnwrap(stack.arrangedSubviews.first as? UIStackView)
        return try XCTUnwrap(row.arrangedSubviews.first as? PKPaymentButton)
    }

    private func render(_ button: PKPaymentButton) -> UIImage {
        UIGraphicsImageRenderer(size: button.bounds.size).image { context in
            button.layer.render(in: context.cgContext)
        }
    }

    func testReportsInitWhenAddedToWindowOnce() throws {
        // Given
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
        let session = CheckoutTestHelpers.makeSession([
            "customer_email": "jenny@example.com",
            "elements_session": [
                "session_id": "es_test",
                "merchant_country": "US",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
                "ordered_payment_method_types_and_wallets": ["link"],
            ],
        ]).makePublicSession(
            expressCheckoutConfiguration: configuration
        )
        let analyticsClient = MockAnalyticsClient()
        let view = ExpressCheckoutElementUIView(
            session: session,
            configuration: configuration,
            delegate: FakeExpressCheckoutElementDelegate(),
            analyticsClient: analyticsClient
        )
        let window = UIWindow()

        // When
        window.addSubview(view)
        view.removeFromSuperview()
        window.addSubview(view)

        // Then
        let analytic = try XCTUnwrap(analyticsClient.loggedAnalytics.first)
        XCTAssertEqual(analyticsClient.loggedAnalytics.count, 1)
        XCTAssertEqual(analytic.event, .expressCheckoutElementInit)
        XCTAssertEqual(analytic.params["ordered_lpms"] as? String, "link")
        XCTAssertEqual(analytic.params["apple_pay_enabled"] as? Bool, StripeAPI.deviceSupportsApplePay())
        XCTAssertEqual(analytic.params["ocr_type"] as? String, PaymentsSDKVariant.ocrTypeString)
        XCTAssertEqual(analytic.params["pay_var"] as? String, PaymentsSDKVariant.variant)
        XCTAssertEqual(
            analytic.params["ece_config"] as? [String: String],
            [
                "link_visibility": "automatic",
                "apple_pay_visibility": "automatic",
            ]
        )
    }

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
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        // Then it stores the available methods in display order
        let expectedPaymentMethods = StripeAPI.deviceSupportsApplePay() ? ["link", "apple_pay"] : ["link"]
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, expectedPaymentMethods)
    }

    func testAvailablePaymentMethodsStoredOnSessionRespectButtonLayout() {
        // Given layouts with and without capacity limits
        let layouts: [(maxColumns: Int?, maxRows: Int?, capacity: Int)] = [
            (nil, nil, 2),
            (1, nil, 2),
            (nil, 1, 2),
            (1, 1, 1),
            (2, 1, 2),
            (1, 2, 2),
        ]
        for layout in layouts {
            var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
            configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
            configuration.appearance.buttonLayout.maxColumns = layout.maxColumns
            configuration.appearance.buttonLayout.maxRows = layout.maxRows

            // When the public session is created with the layout
            let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
                expressCheckoutConfiguration: configuration
            )

            // Then it reports only as many methods as the layout can display
            let eligibleMethodCount = StripeAPI.deviceSupportsApplePay() ? 2 : 1
            XCTAssertEqual(session.availableExpressCheckoutPaymentMethods.count, min(eligibleMethodCount, layout.capacity))
        }
    }

    func testAvailablePaymentMethodsApplyEligibilityBeforeButtonLayout() {
        // Given a single-button layout where the first wallet is disabled
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = .init(merchantId: "merchant.com.example")
        configuration.linkConfiguration.display = .never
        configuration.appearance.buttonLayout.maxColumns = 1
        configuration.appearance.buttonLayout.maxRows = 1

        // When the public session is created
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        // Then the remaining eligible wallet fills the available slot
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, StripeAPI.deviceSupportsApplePay() ? ["apple_pay"] : [])
    }

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    func testLinkButtonHiddenWhenDisplayIsNever() {
        // Given a session with link and a linkConfiguration with display set to .never
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.linkConfiguration = ExpressCheckoutElement.Configuration.LinkConfiguration(display: .never)

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.link))
        XCTAssertTrue(
            ExpressCheckoutElementUtilities.linkDisabledReasonsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
                .contains(.linkConfiguration)
        )
    }

    func testLinkButtonHiddenWhenAutomaticTaxUsesBillingAddress() {
        // Given a session that calculates automatic tax from the billing address
        let apiResponse = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.billing"
        )
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let checkoutConfiguration = CheckoutTestHelpers.makeConfiguration(apiResponse: apiResponse, paymentElementConfiguration: nil)

        // When the public session applies the automatic tax restriction before calculating ECE availability
        XCTAssertFalse(apiResponse.elementsSession.value.disableLinkForAutomaticTaxBilling)
        let session = CheckoutController.Session(apiResponse: apiResponse, localState: .empty, configuration: checkoutConfiguration)

        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasonsWithoutCheckoutRequirements(
            for: session.elementsSession,
            configuration: configuration)

        // Then Link is hidden because it cannot update billing-based automatic tax
        XCTAssertTrue(session.elementsSession.disableLinkForAutomaticTaxBilling)
        XCTAssertFalse(session.availableExpressCheckoutPaymentMethods.contains("link"))
        XCTAssertTrue(reasons.contains(.automaticTaxAddress))
        XCTAssertFalse(
            ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonHiddenWhenShippingAddressIsRequired() {
        // Given a session that requires shipping
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        var elementsSession = CheckoutTestHelpers.minimalElementsSessionJSON
        elementsSession["ordered_payment_method_types_and_wallets"] = ["link"]
        let apiResponse = CheckoutTestHelpers.makeSession([
            "customer_email": "jenny@example.com",
            "shipping_address_collection": ["allowed_countries": ["US"]],
            "elements_session": elementsSession,
        ])
        let session = apiResponse.makePublicSession(expressCheckoutConfiguration: configuration)

        // When
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session.elementsSession,
            configuration: configuration,
            usesWebLink: true,
            requiresShippingAddress: session.requiresShippingAddress,
            billingDetailsCollectionRequired: false
        )

        // Then shipping hides Link
        XCTAssertTrue(reasons.contains(.shippingAddressRequired))
        XCTAssertFalse(session.availableExpressCheckoutPaymentMethods.contains("link"))
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given automatic tax uses shipping but Checkout does not require a shipping address
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let apiResponse = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "session.shipping",
            customerEmail: "jenny@example.com"
        )

        // Then shipping-based automatic tax alone does not hide Link
        let session = apiResponse.makePublicSession(expressCheckoutConfiguration: configuration)
        XCTAssertFalse(session.elementsSession.disableLinkForAutomaticTaxBilling)
        XCTAssertTrue(session.availableExpressCheckoutPaymentMethods.contains("link"))
    }

    func testWebLinkShownWhenCheckoutEmailIsMissing() {
        // Given a Checkout Session without an email and a device using web Link
        let response = makeLinkSession()
        let configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: response, paymentElementConfiguration: nil)

        // Then web Link remains available because its PaymentMethod supplies a billing email
        XCTAssertTrue(ExpressCheckoutElementUtilities.availablePaymentMethods(for: response, configuration: configuration).contains(.link))
    }

    func testWebLinkHiddenWhenBillingAddressCollectionIsRequired() {
        // Given a Checkout Session that requires a billing address and has an email
        let response = makeLinkSession(customerEmail: "jenny@example.com", billingAddressCollectionRequired: true)
        let configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: response, paymentElementConfiguration: nil)

        // Then web Link is hidden, while native Link remains available
        XCTAssertFalse(ExpressCheckoutElementUtilities.availablePaymentMethods(for: response, configuration: configuration).contains(.link))

        let nativeResponse = makeLinkSession(
            customerEmail: "jenny@example.com",
            billingAddressCollectionRequired: true,
            nativeLink: true
        )
        let nativeConfiguration = CheckoutTestHelpers.makeConfiguration(apiResponse: nativeResponse, paymentElementConfiguration: nil)
        XCTAssertTrue(ExpressCheckoutElementUtilities.availablePaymentMethods(for: nativeResponse, configuration: nativeConfiguration).contains(.link))
    }

    func testLinkButtonHiddenWhenDisabledForAutomaticTaxBilling() {
        // Given Link is disabled because the Checkout Session uses automatic tax billing
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession()
        session.elementsSession.disableLinkForAutomaticTaxBilling = true
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        // When
        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)

        // Then
        XCTAssertFalse(buttons.contains(.link))
    }

    func testApplePayButtonHiddenWhenDisabledOnSession() {
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayConfiguration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(buttons, expectedButtons)
    }

    func testAvailablePaymentMethodsStoredOnSessionPreserveSessionOrder() {
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
            merchantId: "merchant.com.example"
        )

        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay", "link"], customerEmail: "jenny@example.com").makePublicSession(
            expressCheckoutConfiguration: configuration
        )

        let expectedPaymentMethods = StripeAPI.deviceSupportsApplePay() ? ["apple_pay", "link"] : ["link"]
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, expectedPaymentMethods)
    }

    private func makeLinkSession(
        customerEmail: String? = nil,
        billingAddressCollectionRequired: Bool = false,
        nativeLink: Bool = false
    ) -> PaymentPagesAPIResponse {
        var elementsSession = CheckoutTestHelpers.minimalElementsSessionJSON
        elementsSession["ordered_payment_method_types_and_wallets"] = ["link"]
        if nativeLink {
            elementsSession["link_settings"] = [
                "link_funding_sources": ["CARD"],
                "link_mobile_use_attestation_endpoints": true,
            ]
        }
        var overrides: [String: Any] = ["elements_session": elementsSession]
        if let customerEmail {
            overrides["customer_email"] = customerEmail
        }
        if billingAddressCollectionRequired {
            overrides["billing_address_collection"] = "required"
        }
        return CheckoutTestHelpers.makeSession(overrides)
    }
}

@MainActor
private final class FakeExpressCheckoutElementDelegate: ExpressCheckoutElementDelegate {
    func expressCheckoutElementShouldConfirm(
        _ paymentMethod: ExpressCheckoutElement.PaymentMethod,
        presentationWindow: UIWindow?
    ) async -> CheckoutController.ConfirmResult {
        return .canceled
    }
}
