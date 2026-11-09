//
//  ExpressCheckoutElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

@MainActor
final class ExpressCheckoutElementViewTests: XCTestCase {

    func testReportsInitWhenAddedToWindowOnce() throws {
        // Given
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let session = CheckoutTestHelpers.makeSession([
            "customer_email": "jenny@example.com",
                "ordered_payment_method_types_and_wallets": ["link"],
            "elements_session_id": "es_test",
            "merchant_info": [
                "country": "US"
            ],
        ]).makePublicSession(
            expressCheckoutConfiguration: configuration,
            applePayMerchantId: "merchant.com.example"
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
        XCTAssertEqual(analytic.params["checkout_session_id"] as? String, session.id)
        XCTAssertEqual(analytic.params["ordered_lpms"] as? String, "link")
        XCTAssertEqual(analytic.params["apple_pay_enabled"] as? Bool, StripeAPI.deviceSupportsApplePay())
        XCTAssertEqual(analytic.params["ocr_type"] as? String, PaymentsSDKVariant.ocrTypeString)
        XCTAssertEqual(analytic.params["pay_var"] as? String, PaymentsSDKVariant.variant)
        XCTAssertEqual(
            analytic.params["ece_config"] as? NSDictionary,
            [
                "link_configuration": ["display": "automatic"],
                "apple_pay_configuration": [String: String](),
                "appearance": [
                    "button_theme": "automatic",
                    "button_layout": [String: String](),
                ],
            ] as NSDictionary
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

    // MARK: - Interaction state

    func testDisabledStateSurvivesButtonRecreation() {
        // Given an element with both wallet buttons
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let view = ExpressCheckoutElementUIView(
            session: session,
            configuration: .init(completion: { _ in }),
            delegate: FakeExpressCheckoutElementDelegate()
        )
        view.update(with: session, buttons: [.applePay, .link])
        let buttons = CheckoutTestHelpers.expressCheckoutButtons(in: view)
        XCTAssertEqual(buttons.count, 2)

        // When the element disables interaction
        view.setEnabled(false)

        // Then the element and both controls are disabled
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertTrue(buttons.allSatisfy { !$0.isEnabled })

        // When the button order changes, forcing the controls to be recreated
        view.update(with: session, buttons: [.link, .applePay])

        // Then the new controls inherit the disabled state
        let recreatedButtons = CheckoutTestHelpers.expressCheckoutButtons(in: view)
        XCTAssertEqual(recreatedButtons.count, 2)
        XCTAssertTrue(recreatedButtons.allSatisfy { button in !buttons.contains { $0 === button } })
        XCTAssertTrue(recreatedButtons.allSatisfy { !$0.isEnabled })

        // ...and enabling the element restores interaction and the new controls
        view.setEnabled(true)
        XCTAssertTrue(view.isUserInteractionEnabled)
        XCTAssertTrue(recreatedButtons.allSatisfy(\.isEnabled))
    }

    func testExpressCheckoutButtonsStayDisabledUntilQueueDrains() async throws {
        // Given an element with an available Link button
        let checkout = try await CheckoutElementsController(configuration: CheckoutTestHelpers.makeConfiguration(
            apiResponse: makeLinkSession(customerEmail: "jenny@example.com"),
            paymentElementConfiguration: nil
        ))
        let view = checkout.getExpressCheckoutElement().uiView
        let button = try XCTUnwrap(CheckoutTestHelpers.expressCheckoutButtons(in: view).first)

        // When two operations are pending
        checkout.pendingOperations = [Task<Void, Error> {}, Task<Void, Error> {}]

        // Then the element stays disabled until both operations leave the queue
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertFalse(button.isEnabled)
        checkout.pendingOperations.removeFirst()
        XCTAssertFalse(view.isUserInteractionEnabled)
        XCTAssertFalse(button.isEnabled)
        checkout.pendingOperations.removeFirst()
        XCTAssertTrue(view.isUserInteractionEnabled)
        XCTAssertTrue(button.isEnabled)
    }

    // MARK: - Available payment methods tests

    func testAvailablePaymentMethodsStoredOnSession() {
        // Given a session listing Link before Apple Pay
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        // When the public session is created with the ECE configuration
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
            expressCheckoutConfiguration: configuration,
            applePayMerchantId: "merchant.com.example"
        )

        // Then it reports the available methods
        let expectedPaymentMethods: Set<ExpressCheckoutElement.PaymentMethod> = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
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
            configuration.appearance.buttonLayout.maxColumns = layout.maxColumns
            configuration.appearance.buttonLayout.maxRows = layout.maxRows

            // When the public session is created with the layout
            let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
                expressCheckoutConfiguration: configuration,
                applePayMerchantId: "merchant.com.example"
            )

            // Then it reports only as many methods as the layout can display
            let eligibleMethodCount = StripeAPI.deviceSupportsApplePay() ? 2 : 1
            XCTAssertEqual(session.availableExpressCheckoutPaymentMethods.count, min(eligibleMethodCount, layout.capacity))
        }
    }

    func testAvailablePaymentMethodsApplyEligibilityBeforeButtonLayout() {
        // Given a single-button layout where the first wallet is disabled
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.linkConfiguration.display = .never
        configuration.appearance.buttonLayout.maxColumns = 1
        configuration.appearance.buttonLayout.maxRows = 1

        // When the public session is created
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"], customerEmail: "jenny@example.com").makePublicSession(
            expressCheckoutConfiguration: configuration,
            applePayMerchantId: "merchant.com.example"
        )

        // Then the remaining eligible wallet fills the available slot
        XCTAssertEqual(session.availableExpressCheckoutPaymentMethods, StripeAPI.deviceSupportsApplePay() ? [.applePay] : [])
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
        // Given a session with apple_pay and an applePayMerchantId
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration, applePayMerchantId: "merchant.com.example")
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
            automaticTaxAddressSource: "billing"
        )
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let checkoutConfiguration = CheckoutTestHelpers.makeConfiguration(apiResponse: apiResponse, paymentElementConfiguration: nil)

        // When the public session applies the automatic tax restriction before calculating ECE availability
        XCTAssertFalse(apiResponse.elementsSession.value.disableLinkForAutomaticTaxBilling)
        let session = CheckoutElementsController.Session(apiResponse: apiResponse, clientSecret: checkoutConfiguration.clientSecret, localState: .empty, configuration: checkoutConfiguration)

        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasonsWithoutCheckoutRequirements(
            for: session.elementsSession,
            configuration: configuration)

        // Then Link is hidden because it cannot update billing-based automatic tax
        XCTAssertTrue(session.elementsSession.disableLinkForAutomaticTaxBilling)
        XCTAssertFalse(session.availableExpressCheckoutPaymentMethods.contains(.link))
        XCTAssertTrue(reasons.contains(.automaticTaxAddress))
        XCTAssertFalse(
            ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration)
                .contains(.link)
        )
    }

    func testLinkButtonHiddenWhenShippingAddressIsRequired() {
        // Given a session that requires shipping
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        var elementsSession = CheckoutTestHelpers.minimalCheckoutClientConfigurationJSON
        elementsSession["ordered_payment_method_types_and_wallets"] = ["link"]
        let apiResponse = CheckoutTestHelpers.makeSession([
            "customer_email": "jenny@example.com",
            "shipping_address_collection": ["allowed_countries": ["US"]],
            ].merging(elementsSession) { _, new in new }
        )
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
        XCTAssertFalse(session.availableExpressCheckoutPaymentMethods.contains(.link))
    }

    func testLinkButtonShownWhenAutomaticTaxUsesShippingAddress() {
        // Given automatic tax uses shipping but Checkout does not require a shipping address
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let apiResponse = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "shipping",
            customerEmail: "jenny@example.com"
        )

        // Then shipping-based automatic tax alone does not hide Link
        let session = apiResponse.makePublicSession(expressCheckoutConfiguration: configuration)
        XCTAssertFalse(session.elementsSession.disableLinkForAutomaticTaxBilling)
        XCTAssertTrue(session.availableExpressCheckoutPaymentMethods.contains(.link))
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
        // Given a session where Apple Pay is disabled server-side, but the merchant has configured applePayMerchantId
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay"], applePayPreference: "disabled").makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration, applePayMerchantId: "merchant.com.example")
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testBothButtonsShownInSessionOrder() {
        // Given a session listing link before apple_pay, with both configured
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link", "apple_pay"]).makePublicSession()
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })

        let buttons = ExpressCheckoutElementUtilities.availablePaymentMethodsWithoutCheckoutRequirements(for: session.elementsSession, configuration: configuration, applePayMerchantId: "merchant.com.example")

        // The order should match the session's wallet ordering, with Apple Pay's inclusion depending on device support
        let expectedButtons: [ExpressCheckoutElement.PaymentMethod] = StripeAPI.deviceSupportsApplePay() ? [.link, .applePay] : [.link]
        XCTAssertEqual(buttons, expectedButtons)
    }

    // MARK: - Helpers

    private func makeLinkSession(
        customerEmail: String? = nil,
        billingAddressCollectionRequired: Bool = false,
        nativeLink: Bool = false
    ) -> CheckoutClientAPIResponse {
        var elementsSession = CheckoutTestHelpers.minimalCheckoutClientConfigurationJSON
        elementsSession["ordered_payment_method_types_and_wallets"] = ["link"]
        if nativeLink {
            elementsSession["link_settings"] = [
                "link_funding_sources": ["CARD"],
                "link_mobile_use_attestation_endpoints": true,
            ]
        }
        var overrides: [String: Any] = [:].merging(elementsSession) { _, new in new }
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
    ) async -> CheckoutElementsController.ConfirmResult {
        return .canceled
    }
}
