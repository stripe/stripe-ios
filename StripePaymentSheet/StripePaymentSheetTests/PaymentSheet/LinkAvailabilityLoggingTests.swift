//
//  LinkAvailabilityLoggingTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import XCTest

@MainActor
final class LinkAvailabilityLoggingTests: XCTestCase {
    private var logs: [String] = []
    private var previousLogger: ((String) -> Void)?

    override func setUp() {
        super.setUp()
        previousLogger = PaymentSheetLoader.availabilityLogger
        PaymentSheetLoader.availabilityLogger = { [weak self] in self?.logs.append($0) }
        LinkAccountContext.shared.account = nil
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = false
    }

    override func tearDown() {
        PaymentSheetLoader.availabilityLogger = previousLogger!
        LinkAccountContext.shared.account = nil
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        super.tearDown()
    }

    func testLogsAllLinkDisabledReasons() {
        // Given a session and configuration that violate each Link requirement
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"])
        elementsSession.disableLinkForAutomaticTaxBilling = true
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .never)
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        configuration.billingDetailsCollectionConfiguration.name = .always

        // When checking availability after loading
        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: configuration)

        // Then all reasons are explained in a single developer-facing message
        let expectedMessage = """
        [Stripe SDK]: PaymentSheet could not offer Link:
        \t* Link is not supported by this Elements Session.
        \t* LinkConfiguration.display is set to .never.
        \t* Card brand filtering requires native Link; the web Link flow does not support it.
        \t* Collecting additional billing details requires native Link; the web Link flow does not support it.
        \t* Checkout Sessions with automatic tax using the billing address do not support Link.
        """
        XCTAssertEqual(logs, [expectedMessage])
    }

    func testDoesNotLogWhenLinkIsAvailableButSignupIsDisabled() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "link"], disableLinkSignup: true)

        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: PaymentSheet.Configuration())

        XCTAssertEqual(logs, [])
    }

    func testGenericFilteringDoesNotReportAvailableLinkAsUnsupported() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "link"])
        let configuration = PaymentSheet.Configuration()

        _ = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: ._testValue(),
            elementsSession: elementsSession,
            configuration: configuration,
            logAvailability: true
        )
        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(logs.contains { $0.hasPrefix("[Stripe SDK]: PaymentSheet could not offer Link:") })
        XCTAssertFalse(logs.contains { $0.hasPrefix("[Stripe SDK]: PaymentSheet could not show the Link button:") })
    }

    func testDoesNotLogWebRestrictionsForNativeLink() {
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "link"])
        var configuration = PaymentSheet.Configuration()
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        configuration.billingDetailsCollectionConfiguration.name = .always

        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: configuration)

        XCTAssertEqual(logs, [])
    }

    func testLogsHiddenWalletButtonWithoutDisablingLink() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "link"])
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .walletButtonHidden)
        LinkAccountContext.shared.account = ._testValue(email: "private@example.com", isRegistered: false)

        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration))
        XCTAssertEqual(logs, ["[Stripe SDK]: PaymentSheet could not show the Link button:\n\t* LinkConfiguration.display is set to .walletButtonHidden and no existing Link user was found."])
    }

    func testDoesNotLogHiddenWalletButtonForExistingUser() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "link"])
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .walletButtonHidden)
        LinkAccountContext.shared.account = ._testValue(email: "private@example.com", isRegistered: true)

        PaymentSheetLoader.logLinkAvailability(elementsSession: elementsSession, configuration: configuration)

        XCTAssertEqual(logs, [])
    }

    func testLogsAllExpressCheckoutLinkDisabledReasons() {
        // Given web Link with incompatible Checkout requirements and display configuration
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.linkConfiguration.display = .never
        let response = CheckoutTestHelpers.makeSession([
            "automatic_tax": ["enabled": true, "status": "ready", "address_source": "billing"],
            "shipping_address_collection": ["allowed_countries": ["US"]],
            "billing_address_collection": "required",
        ])
        let session = response.makePublicSession(expressCheckoutConfiguration: configuration)

        ExpressCheckoutElementUtilities.logLinkAvailability(session: session, configuration: configuration, apiClient: STPAPIClient(publishableKey: "pk_test_123"))

        let expectedMessage = """
        [Stripe SDK]: Express Checkout Element could not offer Link:
        \t* Link is not supported by this Checkout Session.
        \t* LinkConfiguration.display is set to .never.
        \t* Checkout Sessions with automatic tax using the billing address do not support Link.
        \t* The Link button in Express Checkout Element does not support collecting a shipping address.
        \t* Collecting a billing address requires native Link; the web Link flow does not support it.
        """
        XCTAssertEqual(logs, [expectedMessage])
    }

    func testLogsWhenExpressCheckoutLayoutHidesLink() throws {
        guard StripeAPI.deviceSupportsApplePay() else {
            throw XCTSkip("Requires Apple Pay to occupy the only button slot.")
        }
        var configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        configuration.appearance.buttonLayout.maxRows = 1
        configuration.appearance.buttonLayout.maxColumns = 1
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["apple_pay", "link"]).makePublicSession(
            expressCheckoutConfiguration: configuration,
            applePayMerchantId: "merchant.com.example"
        )

        ExpressCheckoutElementUtilities.logLinkAvailability(session: session, configuration: configuration, apiClient: STPAPIClient(publishableKey: "pk_test_123"))

        XCTAssertEqual(logs, ["[Stripe SDK]: Express Checkout Element could not show the Link button:\n\t* The configured button layout does not have room for the Link button."])
    }

    func testDoesNotLogWhenExpressCheckoutLinkIsAvailable() {
        let configuration = ExpressCheckoutElement.Configuration(completion: { _ in })
        let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["link"]).makePublicSession(expressCheckoutConfiguration: configuration)

        ExpressCheckoutElementUtilities.logLinkAvailability(session: session, configuration: configuration, apiClient: STPAPIClient(publishableKey: "pk_test_123"))

        XCTAssertEqual(logs, [])
    }
}
