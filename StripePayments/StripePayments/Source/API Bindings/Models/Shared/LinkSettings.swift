//
//  LinkSettings.swift
//  StripePayments
//
//  Created by Ramon Torres on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// For internal SDK use only
@objc(STP_Internal_LinkSettings)
@_spi(STP) public final class LinkSettings: NSObject, STPAPIResponseDecodable {
    @_spi(STP) @frozen public enum FundingSource: String, Encodable {
        case card = "CARD"
        case bankAccount = "BANK_ACCOUNT"
    }

    @_spi(STP) @frozen public enum PopupWebviewOption: String {
        case shared
        case ephemeral
    }

    @_spi(STP) @frozen public enum LinkDefaultOptIn: String {
        case full = "FULL"
        case optional = "OPTIONAL"
        case none = "NONE"
    }

    @_spi(STP) public let fundingSources: Set<FundingSource>
    @_spi(STP) public let popupWebviewOption: PopupWebviewOption?
    @_spi(STP) public let passthroughModeEnabled: Bool?
    @_spi(STP) public let disableSignup: Bool?
    @_spi(STP) public let suppress2FAModal: Bool?
    @_spi(STP) public let disableFlowControllerRUX: Bool?
    @_spi(STP) public let useAttestationEndpoints: Bool?
    @_spi(STP) public let linkMode: LinkMode?
    @_spi(STP) public let linkFlags: [String: Bool]?
    @_spi(STP) public let linkConsumerIncentive: LinkConsumerIncentive?
    @_spi(STP) public let linkDefaultOptIn: LinkDefaultOptIn?
    @_spi(STP) public let linkEnableDisplayableDefaultValuesInECE: Bool?
    @_spi(STP) public let linkShowPreferDebitCardHint: Bool?
    @_spi(STP) public let attestationStateSyncEnabled: Bool?
    @_spi(STP) public let linkSupportedPaymentMethodsOnboardingEnabled: [String]

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public var instantDebitsOnboardingEnabled: Bool {
        linkSupportedPaymentMethodsOnboardingEnabled.contains("INSTANT_DEBITS")
    }

    @_spi(STP) public init(
        fundingSources: Set<FundingSource>,
        popupWebviewOption: PopupWebviewOption?,
        passthroughModeEnabled: Bool?,
        disableSignup: Bool?,
        suppress2FAModal: Bool?,
        disableFlowControllerRUX: Bool?,
        useAttestationEndpoints: Bool?,
        linkMode: LinkMode?,
        linkFlags: [String: Bool]?,
        linkConsumerIncentive: LinkConsumerIncentive?,
        linkDefaultOptIn: LinkDefaultOptIn?,
        linkEnableDisplayableDefaultValuesInECE: Bool?,
        linkShowPreferDebitCardHint: Bool?,
        attestationStateSyncEnabled: Bool?,
        linkSupportedPaymentMethodsOnboardingEnabled: [String],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.fundingSources = fundingSources
        self.popupWebviewOption = popupWebviewOption
        self.passthroughModeEnabled = passthroughModeEnabled
        self.disableSignup = disableSignup
        self.suppress2FAModal = suppress2FAModal
        self.disableFlowControllerRUX = disableFlowControllerRUX
        self.useAttestationEndpoints = useAttestationEndpoints
        self.linkMode = linkMode
        self.linkFlags = linkFlags
        self.linkConsumerIncentive = linkConsumerIncentive
        self.linkDefaultOptIn = linkDefaultOptIn
        self.linkEnableDisplayableDefaultValuesInECE = linkEnableDisplayableDefaultValuesInECE
        self.linkShowPreferDebitCardHint = linkShowPreferDebitCardHint
        self.attestationStateSyncEnabled = attestationStateSyncEnabled
        self.linkSupportedPaymentMethodsOnboardingEnabled = linkSupportedPaymentMethodsOnboardingEnabled
        self.allResponseFields = allResponseFields
    }

    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard
            let response = response,
            let fundingSourcesStrings = response["link_funding_sources"] as? [String]
        else {
            return nil
        }

        // Server may send down funding sources we haven't implemented yet, so we'll just ignore any unknown sources
        let validFundingSources = Set(fundingSourcesStrings.compactMap(FundingSource.init))

        let webviewOption = PopupWebviewOption(rawValue: response["link_popup_webview_option"] as? String ?? "")
        let passthroughModeEnabled = response["link_passthrough_mode_enabled"] as? Bool ?? false
        let disableSignup = response["link_mobile_disable_signup"] as? Bool ?? false
        let disableFlowControllerRUX = response["link_mobile_disable_rux_in_flow_controller"] as? Bool ?? false
        let useAttestationEndpoints = response["link_mobile_use_attestation_endpoints"] as? Bool ?? false
        let suppress2FAModal = response["link_mobile_suppress_2fa_modal"] as? Bool ?? false
        let linkMode = (response["link_mode"] as? String).flatMap { LinkMode(rawValue: $0) }
        let linkDefaultOptIn = (response["link_default_opt_in"] as? String).flatMap { LinkDefaultOptIn(rawValue: $0) }
        let linkEnableDisplayableDefaultValuesInECE = response["link_enable_displayable_default_values_in_ece"] as? Bool ?? false
        let linkShowPreferDebitCardHint = response["link_show_prefer_debit_card_hint"] as? Bool ?? false
        let attestationStateSyncEnabled = response["link_mobile_attestation_state_sync_enabled"] as? Bool

        let linkIncentivesEnabled = UserDefaults.standard.bool(forKey: "FINANCIAL_CONNECTIONS_INSTANT_DEBITS_INCENTIVES")
        let linkConsumerIncentive: LinkConsumerIncentive? = if linkIncentivesEnabled {
            LinkConsumerIncentive.decodedObject(
                fromAPIResponse: response["link_consumer_incentive"] as? [AnyHashable: Any]
            )
        } else {
            nil
        }

        let linkSupportedPaymentMethodsOnboardingEnabled = response["link_supported_payment_methods_onboarding_enabled"] as? [String] ?? []

        // Collect the flags for the URL generator
        let linkFlags = response.reduce(into: [String: Bool]()) { partialResult, element in
            if let key = element.key as? String, let value = element.value as? Bool {
                partialResult[key] = value
            }
        }

        return LinkSettings(
            fundingSources: validFundingSources,
            popupWebviewOption: webviewOption,
            passthroughModeEnabled: passthroughModeEnabled,
            disableSignup: disableSignup,
            suppress2FAModal: suppress2FAModal,
            disableFlowControllerRUX: disableFlowControllerRUX,
            useAttestationEndpoints: useAttestationEndpoints,
            linkMode: linkMode,
            linkFlags: linkFlags,
            linkConsumerIncentive: linkConsumerIncentive,
            linkDefaultOptIn: linkDefaultOptIn,
            linkEnableDisplayableDefaultValuesInECE: linkEnableDisplayableDefaultValuesInECE,
            linkShowPreferDebitCardHint: linkShowPreferDebitCardHint,
            attestationStateSyncEnabled: attestationStateSyncEnabled,
            linkSupportedPaymentMethodsOnboardingEnabled: linkSupportedPaymentMethodsOnboardingEnabled,
            allResponseFields: response
        ) as? Self
    }

}
