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
