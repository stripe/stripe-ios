//
//  PaymentSheet+PaymentMethodAvailabilityTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/22/25.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentMethodAvailabilityTest: XCTestCase {

    func testIsLinkEnabled_supportsLinkFalse_linkNotPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: false
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when supportsLink is false and link is not in payment method types")
    }

    func testIsLinkEnabled_supportsLinkTrue_linkPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: false
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when isLinkPassthroughModeEnabled is false, since Link is present in the payment method types")
    }

    func testIsLinkEnabled_supportsLinkTrue_linkNotPresent_passthroughEnabled() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when supportsLink is true because passthrough mode is enabled")
    }

    func testIsLinkEnabled_requiresBillingDetailCollection() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true

        )
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when billing details collection is required")
    }

    func testIsLinkEnabled_cardBrandAcceptanceNotAll() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true

        )
        var configuration = PaymentSheet.Configuration()
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when card brand acceptance is not 'all'")
    }

    func testIsLinkEnabled_allConditionsMet() {
        // Given
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card", "link"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when all conditions are met")
    }

    func testIsLinkEnabled_linkNotExplicitlyAllowedButPassthroughEnabled() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when passthrough mode is enabled, even if 'link' is not explicitly in payment method types")
    }

    func testIsLinkEnabled_linkDisplayAutomatic_linkPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .automatic)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when display is set to .automatic")
    }

    func testIsLinkEnabled_linkDisplayNever_linkNotPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            isLinkPassthroughModeEnabled: true
        )
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .never)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when display is set to .never")
    }

    func testIsLinkSignupEnabled_enabled_for_linkSignupOptInFeatureEnabled_if_general_signup_disabled() {
        // Set a test mode publishable key so that we don't check for attestation support
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        STPAPIClient.shared.publishableKey = "pk_test_123"

        // Lookup happened during initialization and an email was provided
        LinkAccountContext.shared.account = ._testValue(email: "john@doe.com", isRegistered: false)

        let elementsSession = STPElementsSession._testValue(
            linkSettings: ._testValue(
                disableSignup: true,
                flags: ["link_sign_up_opt_in_feature_enabled": true]
            )
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkSignupEnabled = PaymentSheet.isLinkSignupEnabled(elementsSession: elementsSession, configuration: configuration)

        STPAPIClient.shared.publishableKey = originalPublishableKey
        XCTAssertTrue(isLinkSignupEnabled, "Link inline signup should be enabled for linkSignupOptInFeatureEnabled even if general signup disabled")
    }

    func testIsLinkSignupEnabled_enabled_for_linkSignupOptInFeatureEnabled_if_email_provided() {
        // Set a test mode publishable key so that we don't check for attestation support
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        STPAPIClient.shared.publishableKey = "pk_test_123"

        // Lookup happened during initialization and an email was provided
        LinkAccountContext.shared.account = ._testValue(email: "john@doe.com", isRegistered: false)

        let elementsSession = STPElementsSession._testValue(
            linkSettings: ._testValue(flags: ["link_sign_up_opt_in_feature_enabled": true])
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkSignupEnabled = PaymentSheet.isLinkSignupEnabled(elementsSession: elementsSession, configuration: configuration)

        STPAPIClient.shared.publishableKey = originalPublishableKey
        XCTAssertTrue(isLinkSignupEnabled, "Link inline signup should be enabled for linkSignupOptInFeatureEnabled if an email was provided")
    }

    func testIsLinkSignupEnabled_disabled_for_linkSignupOptInFeatureEnabled_if_no_email_provided() {
        // Set a test mode publishable key so that we don't check for attestation support
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        STPAPIClient.shared.publishableKey = "pk_test_123"

        // Lookup happened during initialization and no email was provided
        LinkAccountContext.shared.account = nil

        let elementsSession = STPElementsSession._testValue(
            linkSettings: ._testValue(
                disableSignup: true,
                flags: ["link_sign_up_opt_in_feature_enabled": true]
            )
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkSignupEnabled = PaymentSheet.isLinkSignupEnabled(elementsSession: elementsSession, configuration: configuration)

        STPAPIClient.shared.publishableKey = originalPublishableKey
        XCTAssertFalse(isLinkSignupEnabled, "Link inline signup should be disabled for linkSignupOptInFeatureEnabled if no email was provided")
    }
}

extension LinkSettings {
    static func _testValue(
        disableSignup: Bool = false,
        flags: [String: Bool]? = nil,
        linkSupportedPaymentMethodsOnboardingEnabled: [String] = ["CARD"]
    ) -> LinkSettings {
        return .init(
            fundingSources: [.card, .bankAccount],
            popupWebviewOption: nil,
            passthroughModeEnabled: true,
            disableSignup: disableSignup,
            suppress2FAModal: false,
            disableFlowControllerRUX: true,
            useAttestationEndpoints: true,
            linkMode: .passthrough,
            linkFlags: flags,
            linkConsumerIncentive: nil,
            linkDefaultOptIn: nil,
            linkEnableDisplayableDefaultValuesInECE: nil,
            linkShowPreferDebitCardHint: nil,
            attestationStateSyncEnabled: nil,
            linkSupportedPaymentMethodsOnboardingEnabled: linkSupportedPaymentMethodsOnboardingEnabled,
            allResponseFields: [:]
        )
    }
}
