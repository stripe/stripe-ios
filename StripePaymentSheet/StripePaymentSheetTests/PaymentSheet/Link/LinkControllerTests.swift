//
//  LinkControllerTests.swift
//  StripePaymentSheetTests
//

@_spi(InternalOnlyAPI) import StripeCore
import StripePayments
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

@MainActor
final class LinkControllerTests: XCTestCase {

    func testBrandOverrideTakesPriority() {
        // Given a controller whose brand would otherwise resolve to Link, with a Onelink override
        let controller = makeController(initialLinkBrand: .link, brandOverride: .onelink)

        // Then the override is used
        XCTAssertEqual(controller.resolvedLinkBrand, .onelink)
    }

    func testWithoutBrandOverrideUsesResolvedBrand() {
        // Given no signed in customer, and no brand override
        LinkAccountContext.shared.account = nil
        let controller = makeController(initialLinkBrand: .onelink, brandOverride: nil)

        // Then the brand resolved at creation is used
        XCTAssertEqual(controller.resolvedLinkBrand, .onelink)
    }

    // MARK: - Intent configuration

    func testModeIsDerivedFromIntentConfigurationMode() {
        XCTAssertEqual(LinkController.Mode(.setup(currency: nil, setupFutureUsage: .offSession)), .setup)
        XCTAssertEqual(LinkController.Mode(.payment(amount: 1099, currency: "usd")), .payment)
        XCTAssertEqual(
            LinkController.Mode(.payment(amount: 1099, currency: "usd", setupFutureUsage: .offSession)),
            .paymentAndSetupFutureUse
        )
    }

    func testWithoutIntentConfigurationCollectsPaymentMethodsInSetupMode() throws {
        // Given a Link configuration with intent payment method types and Financial Connections permissions
        let linkConfiguration = LinkConfiguration(paymentMethodTypes: ["link"], financialConnectionsPermissions: ["balances"])

        // When making the intent configuration without a merchant intent configuration
        let (intentConfiguration, recorder) = try LinkController.makeIntentConfiguration(nil, linkConfiguration: linkConfiguration)

        // Then the controller only collects payment methods, in off-session setup mode
        XCTAssertNil(recorder)
        guard case let .setup(currency, setupFutureUsage) = intentConfiguration.mode else {
            return XCTFail("Expected setup mode, got \(intentConfiguration.mode)")
        }
        XCTAssertNil(currency)
        XCTAssertEqual(setupFutureUsage, .offSession)
        XCTAssertEqual(intentConfiguration.paymentMethodTypes, ["link"])
        XCTAssertEqual(intentConfiguration.financialConnectionsPermissions, ["balances"])
    }

    func testWithIntentConfigurationRecordsConfirmedPaymentMethod() async throws {
        // Given a merchant intent configuration in payment mode
        let merchantIntentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "usd")
        ) { _, _ in "pi_123_secret_abc" }
        let linkConfiguration = LinkConfiguration(paymentMethodTypes: ["link"], financialConnectionsPermissions: ["balances"])

        // When making the intent configuration to load with
        let (intentConfiguration, recorder) = try LinkController.makeIntentConfiguration(
            merchantIntentConfiguration,
            linkConfiguration: linkConfiguration
        )

        // Then it keeps the merchant's mode, and fills in the Link configuration's values
        guard case let .payment(amount, currency, _, _, _) = intentConfiguration.mode else {
            return XCTFail("Expected payment mode, got \(intentConfiguration.mode)")
        }
        XCTAssertEqual(amount, 1099)
        XCTAssertEqual(currency, "usd")
        XCTAssertEqual(intentConfiguration.paymentMethodTypes, ["link"])
        XCTAssertEqual(intentConfiguration.financialConnectionsPermissions, ["balances"])

        // When Link calls the confirm handler
        let paymentMethod = STPPaymentMethod._testCard()
        let clientSecret = try await intentConfiguration.confirmHandler?(paymentMethod, false)

        // Then it returns the merchant's client secret
        XCTAssertEqual(clientSecret, "pi_123_secret_abc")
        // ...and records the payment method for `present` to return
        XCTAssertEqual(recorder?.paymentMethod?.stripeId, paymentMethod.stripeId)
    }

    func testIntentConfigurationWithoutConfirmHandlerIsUnsupported() {
        // Given a merchant intent configuration that only has a confirmation token handler
        let merchantIntentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "usd"),
            confirmationTokenConfirmHandler: { _ in "pi_123_secret_abc" }
        )

        // When making the intent configuration to load with
        // Then it fails because LinkController needs a payment method confirm handler
        XCTAssertThrowsError(try LinkController.makeIntentConfiguration(merchantIntentConfiguration, linkConfiguration: nil)) { error in
            XCTAssertEqual(error as? LinkController.IntegrationError, .unsupportedIntentConfiguration)
        }
    }

    // MARK: - Link web popup

    func testWebLinkCanSatisfyDefaultConfiguration() {
        XCTAssertTrue(LinkController.webLinkCanSatisfy(configuration: PaymentSheet.Configuration(), linkConfiguration: nil))
        XCTAssertTrue(LinkController.webLinkCanSatisfy(configuration: PaymentSheet.Configuration(), linkConfiguration: LinkConfiguration()))
        // ...and every payment method type, which isn't a restriction
        XCTAssertTrue(LinkController.webLinkCanSatisfy(
            configuration: PaymentSheet.Configuration(),
            linkConfiguration: LinkConfiguration(supportedPaymentMethodTypes: LinkPaymentMethodType.allCases)
        ))
    }

    func testWebLinkCantCollectBillingDetails() {
        // Given a Link configuration that collects the customer's name
        var billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingDetailsCollectionConfiguration.name = .always
        let linkConfiguration = LinkConfiguration(billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration)

        // Then the web popup can't satisfy it
        XCTAssertFalse(LinkController.webLinkCanSatisfy(configuration: PaymentSheet.Configuration(), linkConfiguration: linkConfiguration))
    }

    func testWebLinkCantLimitPaymentMethodTypes() {
        // Given a Link configuration that only offers cards
        let linkConfiguration = LinkConfiguration(supportedPaymentMethodTypes: [.card])

        // Then the web popup can't satisfy it
        XCTAssertFalse(LinkController.webLinkCanSatisfy(configuration: PaymentSheet.Configuration(), linkConfiguration: linkConfiguration))
    }

    func testWithoutNativeLinkUnsatisfiableConfigurationFailsCreation() {
        // Given a device that can't use native Link, and a Link session with funding sources
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false
        defer { PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil }
        let elementsSession = STPElementsSession._testValue(intent: ._testValue(), linkFundingSources: [ParsedEnum(.card)])

        // Then the web popup is allowed for the default configuration
        XCTAssertNil(LinkController.linkUnavailableError(
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration(),
            linkConfiguration: nil
        ))
        // ...but not for a configuration that needs native Link
        XCTAssertEqual(
            LinkController.linkUnavailableError(
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                linkConfiguration: LinkConfiguration(supportedPaymentMethodTypes: [.card])
            ),
            .configurationRequiresNativeLink
        )
    }

    func testWithNativeLinkAnyConfigurationIsAllowed() {
        // Given a device that can use native Link
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        defer { PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil }
        let elementsSession = STPElementsSession._testValue(intent: ._testValue(), linkFundingSources: [ParsedEnum(.card)])

        // Then a configuration that the web popup can't satisfy is still allowed
        XCTAssertNil(LinkController.linkUnavailableError(
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration(),
            linkConfiguration: LinkConfiguration(supportedPaymentMethodTypes: [.card])
        ))
    }

    func testWithoutFundingSourcesLinkIsUnavailable() {
        let elementsSession = STPElementsSession._testValue(intent: ._testValue(), linkFundingSources: [])
        XCTAssertEqual(
            LinkController.linkUnavailableError(elementsSession: elementsSession, configuration: PaymentSheet.Configuration(), linkConfiguration: nil),
            .linkUnavailable
        )
    }

    func testWebPaymentMethodPreviewShowsCard() {
        // Given a card payment method returned by the Link web popup
        let paymentMethod = STPPaymentMethod._testCard()
        let paymentOption: PaymentOption = .link(option: .withPaymentMethod(brand: .link, paymentMethod: paymentMethod))

        // When making its preview
        let preview = LinkController.webPaymentMethodPreview(for: paymentOption, linkBrand: .link, reduceLinkBranding: false)

        // Then it shows the card
        XCTAssertEqual(preview?.paymentMethodType, .card)
        XCTAssertEqual(preview?.label, LinkBrand.link.displayName)
        XCTAssertEqual(preview?.sublabel?.hasSuffix(paymentMethod.card?.last4 ?? "-"), true)
    }

    func testWebPaymentMethodPreviewIsNilWithoutCard() {
        XCTAssertNil(LinkController.webPaymentMethodPreview(for: nil, linkBrand: .link, reduceLinkBranding: false))
    }

    // MARK: - Helpers

    private func makeController(initialLinkBrand: LinkBrand, brandOverride: LinkBrand?) -> LinkController {
        var paymentElementConfiguration = PaymentSheet.Configuration()
        paymentElementConfiguration.link.brand = brandOverride
        return LinkController(
            mode: .setup,
            elementsSession: ._testValue(intent: ._testValue()),
            intent: ._testValue(),
            paymentElementConfiguration: paymentElementConfiguration,
            linkBrand: initialLinkBrand,
            appearance: nil,
            configuration: nil,
            analyticsHelper: ._testValue(),
            requestSurface: .standaloneLink
        )
    }
}
