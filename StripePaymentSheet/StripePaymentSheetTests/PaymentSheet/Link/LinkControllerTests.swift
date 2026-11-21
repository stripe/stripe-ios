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

    func testWithoutIntentConfigurationCollectsPaymentMethodsInSetupMode() {
        // Given a Link configuration with intent payment method types and Financial Connections permissions
        let linkConfiguration = LinkConfiguration(paymentMethodTypes: ["link"], financialConnectionsPermissions: ["balances"])

        // When making the intent configuration without a merchant intent configuration
        let intentConfiguration = LinkController.makeIntentConfiguration(nil, linkConfiguration: linkConfiguration)

        // Then the controller only collects payment methods, in off-session setup mode
        guard case let .setup(currency, setupFutureUsage) = intentConfiguration.mode else {
            return XCTFail("Expected setup mode, got \(intentConfiguration.mode)")
        }
        XCTAssertNil(currency)
        XCTAssertEqual(setupFutureUsage, .offSession)
        XCTAssertEqual(intentConfiguration.paymentMethodTypes, ["link"])
        XCTAssertEqual(intentConfiguration.financialConnectionsPermissions, ["balances"])
    }

    func testWithIntentConfigurationKeepsMerchantConfirmHandler() async throws {
        // Given a merchant intent configuration in payment mode
        let merchantIntentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "usd")
        ) { _, _ in "pi_123_secret_abc" }
        let linkConfiguration = LinkConfiguration(paymentMethodTypes: ["link"], financialConnectionsPermissions: ["balances"])

        // When making the intent configuration to load with
        let intentConfiguration = LinkController.makeIntentConfiguration(
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

        // ...and the merchant's confirm handler
        let clientSecret = try await intentConfiguration.confirmHandler?(STPPaymentMethod._testCard(), false)
        XCTAssertEqual(clientSecret, "pi_123_secret_abc")
    }

    func testWithConfirmationTokenIntentConfigurationKeepsMerchantHandler() async throws {
        // Given a merchant intent configuration that confirms with confirmation tokens
        let merchantIntentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "usd"),
            confirmationTokenConfirmHandler: { _ in "pi_123_secret_abc" }
        )

        // When making the intent configuration to load with
        let intentConfiguration = LinkController.makeIntentConfiguration(merchantIntentConfiguration, linkConfiguration: nil)

        // Then it's supported, and keeps the merchant's confirmation token handler
        XCTAssertNotNil(intentConfiguration.confirmationTokenConfirmHandler)
    }

    func testPaymentMethodResultPaymentMethod() {
        let paymentMethod = STPPaymentMethod._testCard()
        XCTAssertEqual(LinkController.PaymentMethodResult.completed(paymentMethod).paymentMethod?.stripeId, paymentMethod.stripeId)
        XCTAssertEqual(LinkController.PaymentMethodResult.confirmed(paymentMethod).paymentMethod?.stripeId, paymentMethod.stripeId)
        XCTAssertNil(LinkController.PaymentMethodResult.canceled.paymentMethod)
    }

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

    func testWebPaymentMethodPreviewShowsBankAccount() {
        // Given a bank account payment method returned by the Link web popup
        let paymentMethod = LinkWalletButtonUIViewTests.bankAccountPaymentMethod()
        let paymentOption: PaymentOption = .link(option: .withPaymentMethod(brand: .link, paymentMethod: paymentMethod))

        // When making its preview
        let preview = LinkController.webPaymentMethodPreview(for: paymentOption, linkBrand: .link, reduceLinkBranding: false)

        // Then it shows the bank account like native Link does
        XCTAssertEqual(preview?.paymentMethodType, .bankAccount)
        XCTAssertEqual(preview?.label, LinkBrand.link.displayName)
        XCTAssertEqual(preview?.sublabel, "STRIPE TEST BANK •••• 6789")
    }

    func testWebPaymentMethodPreviewOnlyShowsLinkForCardBrandToken() {
        // Given a card-brand token returned by the Link web popup, e.g. for a bank account selected in Link
        let paymentMethod = LinkWalletButtonUIViewTests.linkCardBrandTokenPaymentMethod()
        XCTAssertTrue(paymentMethod.isLinkCardBrandToken)
        let paymentOption: PaymentOption = .link(option: .withPaymentMethod(brand: .link, paymentMethod: paymentMethod))

        // When making its preview
        let preview = LinkController.webPaymentMethodPreview(for: paymentOption, linkBrand: .link, reduceLinkBranding: false)

        // Then it only shows Link, rather than the token's placeholder card details
        XCTAssertEqual(preview?.label, LinkBrand.link.displayName)
        XCTAssertNil(preview?.sublabel)
    }

    func testRegularCardIsNotLinkCardBrandToken() {
        XCTAssertFalse(STPPaymentMethod._testCard().isLinkCardBrandToken)
        XCTAssertFalse(LinkWalletButtonUIViewTests.bankAccountPaymentMethod().isLinkCardBrandToken)
    }

    func testWebPaymentMethodPreviewIsNilWithoutCard() {
        XCTAssertNil(LinkController.webPaymentMethodPreview(for: nil, linkBrand: .link, reduceLinkBranding: false))
    }

    // MARK: - Link wallet button

    func testIntentMismatchIsDetectedFromClientSecret() {
        // A SetupIntent's client secret for a payment, and the other way around
        XCTAssertEqual(LinkController.intentMismatchError(clientSecret: "seti_123_secret_abc", isPayment: true), .intentMismatch)
        XCTAssertEqual(LinkController.intentMismatchError(clientSecret: "pi_123_secret_abc", isPayment: false), .intentMismatch)
        // ...matching client secrets
        XCTAssertNil(LinkController.intentMismatchError(clientSecret: "pi_123_secret_abc", isPayment: true))
        XCTAssertNil(LinkController.intentMismatchError(clientSecret: "seti_123_secret_abc", isPayment: false))
        // ...and malformed ones, which fail when the intent is loaded
        XCTAssertNil(LinkController.intentMismatchError(clientSecret: "not_a_client_secret", isPayment: true))
    }

    func testPresentFailsWhenClientSecretProviderThrows() {
        // Given a Link wallet button controller whose client secret provider fails
        struct ProviderError: Error {}
        let controller = makeController(
            initialLinkBrand: .link,
            brandOverride: nil,
            buttonMode: .payment(clientSecretProvider: { throw ProviderError() })
        )

        // When Link is presented
        let presented = expectation(description: "present completes")
        controller.present(email: nil, from: UIViewController()) { result in
            // Then it fails with the provider's error, without opening Link
            guard case .failure(let error) = result else {
                return XCTFail("Expected a failure, got \(result)")
            }
            XCTAssertTrue(error is ProviderError)
            presented.fulfill()
        }
        wait(for: [presented], timeout: 5)
    }

    func testPresentFailsForMismatchedClientSecret() {
        // Given a Link wallet button controller for a payment, whose provider returns a SetupIntent's client secret
        let controller = makeController(
            initialLinkBrand: .link,
            brandOverride: nil,
            buttonMode: .payment(clientSecretProvider: { "seti_123_secret_abc" })
        )

        // When Link is presented
        let presented = expectation(description: "present completes")
        controller.present(email: nil, from: UIViewController()) { result in
            // Then it fails before loading the intent
            guard case .failure(let error) = result else {
                return XCTFail("Expected a failure, got \(result)")
            }
            XCTAssertEqual(error as? LinkController.IntegrationError, .intentMismatch)
            presented.fulfill()
        }
        wait(for: [presented], timeout: 5)
    }

    // MARK: - Helpers

    private func makeController(
        initialLinkBrand: LinkBrand,
        brandOverride: LinkBrand?,
        buttonMode: LinkWalletButtonViewModel.Mode? = nil
    ) -> LinkController {
        var paymentElementConfiguration = PaymentSheet.Configuration()
        paymentElementConfiguration.link.brand = brandOverride
        return LinkController(
            mode: buttonMode.map(LinkController.Mode.init) ?? .setup,
            elementsSession: ._testValue(intent: ._testValue()),
            intent: ._testValue(),
            buttonMode: buttonMode,
            paymentElementConfiguration: paymentElementConfiguration,
            linkBrand: initialLinkBrand,
            appearance: nil,
            configuration: nil,
            analyticsHelper: ._testValue(),
            requestSurface: .standaloneLink
        )
    }
}
