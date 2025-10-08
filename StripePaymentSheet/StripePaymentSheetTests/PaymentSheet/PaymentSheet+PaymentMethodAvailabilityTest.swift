//
//  PaymentSheet+PaymentMethodAvailabilityTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/22/25.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentMethodAvailabilityTest: XCTestCase {

    func testIsLinkEnabled_linkModeNil() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: nil
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when linkMode is nil")
    }

    func testIsLinkEnabled_requiresBillingDetailCollection() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: .passthrough
        )
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when billing details collection is required")
    }

    func testIsLinkEnabled_cardBrandAcceptanceNotAll() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: .passthrough
        )
        var configuration = PaymentSheet.Configuration()
        configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertFalse(isLinkEnabled, "Link should be disabled when card brand acceptance is not 'all'")
    }

    func testIsLinkEnabled_linkModePresent() {
        // Given
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: .passthrough,
            linkFundingSources: [.card, .bankAccount]
        )
        let configuration = PaymentSheet.Configuration()
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when all conditions are met")
    }

    func testIsLinkEnabled_linkDisplayAutomatic_linkPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: .passthrough,
            linkFundingSources: [.card, .bankAccount]
        )
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .automatic)
        let isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)

        XCTAssertTrue(isLinkEnabled, "Link should be enabled when display is set to .automatic")
    }

    func testIsLinkEnabled_linkDisplayNever_linkNotPresent() {
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            linkMode: .passthrough
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
        linkMode: LinkMode? = .passthrough,
        linkSupportedPaymentMethodsOnboardingEnabled: [String] = ["CARD"]
    ) -> LinkSettings {
        return .init(
            fundingSources: [.card, .bankAccount],
            popupWebviewOption: nil,
            passthroughModeEnabled: linkMode == .passthrough || linkMode == .linkCardBrand,
            disableSignup: disableSignup,
            suppress2FAModal: false,
            disableFlowControllerRUX: true,
            useAttestationEndpoints: true,
            linkMode: linkMode,
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
