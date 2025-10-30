//
//  STPElementsSession.swift
//  StripePayments
//
//  Created by Nick Porter on 2/15/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The response returned by v1/elements/sessions
@_spi(STP) public final class STPElementsSession: NSObject {
    #if DEBUG && targetEnvironment(simulator)
    public static let countryCodeOverride: String? = nil
    #endif
    /// Elements Session ID for analytics purposes, looks like "elements_session_1234"
    let sessionID: String

    /// Backend-logged Elements Session Config ID
    let configID: String?

    /// The ordered payment method preference for this ElementsSession.
    let orderedPaymentMethodTypes: [STPPaymentMethodType]

    /// The ordered payment method and wallet types for this ElementsSession.
    let orderedPaymentMethodTypesAndWallets: [String]

    /// A list of payment method types that are not activated in live mode, but activated in test mode.
    let unactivatedPaymentMethodTypes: [STPPaymentMethodType]

    /// Link-specific settings for this ElementsSession.
    let linkSettings: LinkSettings?

    /// Experiment assignments and `arb_id` to allow logging exposure events.
    let experimentsData: ExperimentsData?

    /// Flags for this ElementsSession.
    let flags: [String: Bool]

    /// Country code of the user.
    let countryCode: String?

    /// Country code of the merchant.
    let merchantCountryCode: String?

    /// Link to the merchant's logo asset.
    let merchantLogoUrl: URL?

    /// A map describing payment method types form specs.
    let paymentMethodSpecs: [[AnyHashable: Any]]?

    /// Card brand choice settings for the merchant.
    let cardBrandChoice: STPCardBrandChoice?

    let isApplePayEnabled: Bool

    /// An ordered list of external payment methods to display
    let externalPaymentMethods: [ExternalPaymentMethod]

    /// An ordered list of custom payment methods to display
    let customPaymentMethods: [CustomPaymentMethod]

    /// An object that contains information for the passive captcha
    let passiveCaptchaData: PassiveCaptchaData?

    let customer: ElementsCustomer?

    /// A flag that indicates that this instance was created as a best-effort
    let isBackupInstance: Bool

    public let allResponseFields: [AnyHashable: Any]

    internal init(
        allResponseFields: [AnyHashable: Any],
        sessionID: String,
        configID: String?,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        orderedPaymentMethodTypesAndWallets: [String],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        merchantCountryCode: String?,
        merchantLogoUrl: URL?,
        linkSettings: LinkSettings?,
        experimentsData: ExperimentsData?,
        flags: [String: Bool],
        paymentMethodSpecs: [[AnyHashable: Any]]?,
        cardBrandChoice: STPCardBrandChoice?,
        isApplePayEnabled: Bool,
        externalPaymentMethods: [ExternalPaymentMethod],
        customPaymentMethods: [CustomPaymentMethod],
        passiveCaptchaData: PassiveCaptchaData?,
        customer: ElementsCustomer?,
        isBackupInstance: Bool = false
    ) {
        self.allResponseFields = allResponseFields
        self.sessionID = sessionID
        self.configID = configID
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.orderedPaymentMethodTypesAndWallets = orderedPaymentMethodTypesAndWallets
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        self.countryCode = countryCode
        self.merchantCountryCode = merchantCountryCode
        self.merchantLogoUrl = merchantLogoUrl
        self.linkSettings = linkSettings
        self.experimentsData = experimentsData
        self.flags = flags
        self.paymentMethodSpecs = paymentMethodSpecs
        self.cardBrandChoice = cardBrandChoice
        self.isApplePayEnabled = isApplePayEnabled
        self.externalPaymentMethods = externalPaymentMethods
        self.customPaymentMethods = customPaymentMethods
        self.passiveCaptchaData = passiveCaptchaData
        self.customer = customer
        self.isBackupInstance = isBackupInstance
        super.init()
    }

    /// Returns a "best effort" STPElementsSessions object to be used as a last resort fallback if the endpoint failed to return a response or we failed to parse it.
    static func makeBackupElementsSession(with paymentIntent: STPPaymentIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: paymentIntent.allResponseFields,
            paymentMethodTypes: paymentIntent.paymentMethodTypes
        )
    }

    static func makeBackupElementsSession(with setupIntent: STPSetupIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: setupIntent.allResponseFields,
            paymentMethodTypes: setupIntent.paymentMethodTypes
        )
    }

    /// Returns a "best effort" STPElementsSessions object to be used as a last resort fallback if the endpoint failed to return a response or we failed to parse it.
    static func makeBackupElementsSession(allResponseFields: [AnyHashable: Any], paymentMethodTypes: [STPPaymentMethodType]) -> STPElementsSession {
        var sortedPaymentMethodTypes = paymentMethodTypes
        // .remove returns the removed value if it exists
        if sortedPaymentMethodTypes.remove(.card) != nil {
            sortedPaymentMethodTypes.insert(.card, at: 0)
        }
        return STPElementsSession(
            allResponseFields: allResponseFields,
            sessionID: UUID().uuidString,
            configID: nil,
            orderedPaymentMethodTypes: sortedPaymentMethodTypes,
            orderedPaymentMethodTypesAndWallets: [],
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            merchantLogoUrl: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: STPCardBrandChoice.decodedObject(fromAPIResponse: [:]),
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: nil,
            customer: nil,
            isBackupInstance: true
        )
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsSession: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        // Required fields:
        guard let response,
              let paymentMethodPrefDict = response["payment_method_preference"] as? [AnyHashable: Any],
              let paymentMethodTypeStrings = paymentMethodPrefDict["ordered_payment_method_types"] as? [String],
              let sessionID = response["session_id"] as? String
        else {
            return nil
        }

        let configID = response["config_id"] as? String
        // Optional fields:
        let unactivatedPaymentMethodTypeStrings = response["unactivated_payment_method_types"] as? [String] ?? []
        let orderedPaymentMethodTypesAndWallets = response["ordered_payment_method_types_and_wallets"] as? [String] ?? []
        let cardBrandChoice = STPCardBrandChoice.decodedObject(fromAPIResponse: response["card_brand_choice"] as? [AnyHashable: Any])
        let applePayPreference = response["apple_pay_preference"] as? String
        let isApplePayEnabled = applePayPreference != "disabled"
        let flags = response["flags"] as? [String: Bool] ?? [:]
        let customer: ElementsCustomer? = {
            let customerDataKey = "customer"
            guard response[customerDataKey] != nil, !(response[customerDataKey] is NSNull) else {
                return nil
            }
            let enableLinkInSPM = flags["elements_enable_link_spm"] ?? false
            guard let customerJSON = response[customerDataKey] as? [AnyHashable: Any],
                  let decoded = ElementsCustomer.decoded(fromAPIResponse: customerJSON, enableLinkInSPM: enableLinkInSPM) else {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionCustomerDeserializeFailed)
                return nil
            }
            return decoded
        }()

        let externalPaymentMethods: [ExternalPaymentMethod] = {
            let externalPaymentMethodDataKey = "external_payment_method_data"
            guard response[externalPaymentMethodDataKey] != nil, !(response[externalPaymentMethodDataKey] is NSNull) else {
                return []
            }
            guard
                let epmsJSON = response[externalPaymentMethodDataKey] as? [[AnyHashable: Any]],
                let epms = ExternalPaymentMethod.decoded(fromAPIResponse: epmsJSON)
            else {
                // We don't want to fail the entire v1/elements/sessions request if we fail to parse external_payment_methods_data
                // Instead, fall back to an empty array and log an error.
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionEPMLoadFailed)
                return []
            }
            return epms
        }()

        let passiveCaptchaData: PassiveCaptchaData? = {
            let enablePassiveCaptcha = flags["elements_enable_passive_captcha"] ?? false
            let passiveCaptchaKey = "passive_captcha"
            guard enablePassiveCaptcha,
                  let passiveCaptchaJSON = response[passiveCaptchaKey] as? [AnyHashable: Any],
                  let passiveCaptchaData = PassiveCaptchaData.decoded(fromAPIResponse: passiveCaptchaJSON)
            else {
                return nil
            }
            return passiveCaptchaData
        }()

        let customPaymentMethods: [CustomPaymentMethod] = {
            let customPaymentMethodDataKey = "custom_payment_method_data"
            guard response[customPaymentMethodDataKey] != nil, !(response[customPaymentMethodDataKey] is NSNull) else {
                return []
            }
            guard
                let cpmsJSON = response[customPaymentMethodDataKey] as? [[AnyHashable: Any]],
                let cpms = CustomPaymentMethod.decoded(fromAPIResponse: cpmsJSON)
            else {
                // We don't want to fail the entire v1/elements/sessions request if we fail to parse custom_payment_methods_data
                // Instead, fall back to an empty array and log an error.
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetElementsSessionCPMLoadFailed)
                return []
            }
            return cpms
        }()

        return self.init(
            allResponseFields: response,
            sessionID: sessionID,
            configID: configID,
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            orderedPaymentMethodTypesAndWallets: orderedPaymentMethodTypesAndWallets,
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            merchantCountryCode: response["merchant_country"] as? String,
            merchantLogoUrl: (response["merchant_logo_url"] as? String).flatMap { URL(string: $0) },
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: response["link_settings"] as? [AnyHashable: Any]
            ),
            experimentsData: ExperimentsData.decodedObject(
                fromAPIResponse: response["experiments_data"] as? [AnyHashable: Any]
            ),
            flags: flags,
            paymentMethodSpecs: response["payment_method_specs"] as? [[AnyHashable: Any]],
            cardBrandChoice: cardBrandChoice,
            isApplePayEnabled: isApplePayEnabled,
            externalPaymentMethods: externalPaymentMethods,
            customPaymentMethods: customPaymentMethods,
            passiveCaptchaData: passiveCaptchaData,
            customer: customer
        )
    }
}

// MARK: - Extensions
extension STPElementsSession {
    var isCardBrandChoiceEligible: Bool {
        return cardBrandChoice?.eligible ?? false
    }

    var enableLinkInSPM: Bool {
        flags["elements_enable_link_spm"] ?? false
    }

    func allowsRemovalOfPaymentMethodsForPaymentSheet() -> Bool {
        var allowsRemovalOfPaymentMethods = false
        if let customerSession = customer?.customerSession {
            if customerSession.mobilePaymentElementComponent.enabled,
               let features = customerSession.mobilePaymentElementComponent.features {
                allowsRemovalOfPaymentMethods = features.paymentMethodRemove == .enabled || features.paymentMethodRemove == .partial
            }
        } else {
            allowsRemovalOfPaymentMethods = true
        }
        return allowsRemovalOfPaymentMethods
    }

    func paymentMethodRemoveIsPartialForPaymentSheet() -> Bool {
        let isParital = false
        if let customerSession = customer?.customerSession {
            if customerSession.mobilePaymentElementComponent.enabled,
               let features = customerSession.mobilePaymentElementComponent.features {
                return features.paymentMethodRemove == .partial
            }
        }
        return isParital
    }

    func paymentMethodRemoveLast(configuration: PaymentElementConfiguration) -> Bool{
        if !configuration.allowsRemovalOfLastSavedPaymentMethod {
            // Merchant has set local configuration to false, so honor it.
            return false
        } else {
            // Merchant is using client side default, so defer to CustomerSession's value
            return customer?.customerSession.mobilePaymentElementComponent.features?.paymentMethodRemoveLast ?? true
        }
    }

    var paymentMethodSetAsDefaultForPaymentSheet: Bool {
        return customer?.customerSession.mobilePaymentElementComponent.features?.paymentMethodSetAsDefault ?? false
    }

    var paymentMethodUpdateForPaymentSheet: Bool {
        return customer?.customerSession.mobilePaymentElementComponent.enabled ?? false
    }

    var paymentMethodUpdateForCustomerSheet: Bool {
        return customer?.customerSession.customerSheetComponent.enabled ?? false
    }

    func allowsRemovalOfPaymentMethodsForCustomerSheet() -> Bool {
        var allowsRemovalOfPaymentMethods = false
        if let customerSession = customer?.customerSession {
            if customerSession.customerSheetComponent.enabled,
               let features = customerSession.customerSheetComponent.features {
                allowsRemovalOfPaymentMethods = features.paymentMethodRemove == .enabled || features.paymentMethodRemove == .partial
            }
        } else {
            allowsRemovalOfPaymentMethods = true
        }
        return allowsRemovalOfPaymentMethods
    }
    func paymentMethodRemoveIsPartialForCustomerSheet() -> Bool {
        let isParital = false
        if let customerSession = customer?.customerSession {
            if customerSession.customerSheetComponent.enabled,
               let features = customerSession.customerSheetComponent.features {
                return features.paymentMethodRemove == .partial
            }
        }
        return isParital
    }
    var paymentMethodRemoveLastForCustomerSheet: Bool {
        return customer?.customerSession.customerSheetComponent.features?.paymentMethodRemoveLast ?? true
    }

    var paymentMethodSyncDefaultForCustomerSheet: Bool {
        return customer?.customerSession.customerSheetComponent.features?.paymentMethodSyncDefault ?? false
    }

    var isLinkCardBrand: Bool {
        linkSettings?.linkMode == .linkCardBrand
    }

    var incentive: PaymentMethodIncentive? {
        linkSettings?.linkConsumerIncentive.flatMap(PaymentMethodIncentive.init)
    }

    var allowsLinkDefaultOptIn: Bool {
        linkFlags["link_mobile_disable_default_opt_in"] != true
    }

    var forceSaveFutureUseBehaviorAndNewMandateText: Bool {
        flags["elements_mobile_force_setup_future_use_behavior_and_new_mandate_text"] == true
    }

    var linkSignupOptInFeatureEnabled: Bool {
        linkFlags["link_sign_up_opt_in_feature_enabled"] == true
    }

    var linkSignupOptInInitialValue: Bool {
        linkFlags["link_sign_up_opt_in_initial_value"] == true
    }

    var shouldAttestOnConfirmation: Bool {
        flags["elements_mobile_attest_on_intent_confirmation"] == true
    }
}

extension STPElementsSession {
    var savePaymentMethodConsentBehavior: PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        guard let paymentMethodSave = customerSessionMobilePaymentElementFeatures?.paymentMethodSave else {
            return .legacy
        }
        return paymentMethodSave
        ? .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled
        : .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled
    }

    var customerSessionMobilePaymentElementFeatures: MobilePaymentElementComponentFeature? {
        guard let customerSession = customer?.customerSession,
              customerSession.mobilePaymentElementComponent.enabled else {
            return nil
        }
        return customerSession.mobilePaymentElementComponent.features
    }
}

extension STPElementsSession {
    func savePaymentMethodConsentBehaviorForCustomerSheet() -> PaymentSheetFormFactory.SavePaymentMethodConsentBehavior {
        return customerSessionCustomerSheet() ? .customerSheetWithCustomerSession : .legacy
    }

    func customerSessionCustomerSheet() -> Bool {
        guard let customerSession = customer?.customerSession,
              customerSession.customerSheetComponent.enabled else {
            return false
        }
        return true
    }
}

extension STPElementsSession {
    func computeAllowRedisplay(isSettingUp: Bool) -> STPPaymentMethodAllowRedisplay? {
        guard let customerSessionMobilePaymentElementFeatures else {
            return nil
        }

        let allowRedisplayOverride = customerSessionMobilePaymentElementFeatures.paymentMethodSaveAllowRedisplayOverride

        if isSettingUp {
            return allowRedisplayOverride ?? .limited
        } else {
            return .unspecified
        }
    }

    var useCardPaymentMethodTypeForIBP: Bool {
        let canAcceptACH = orderedPaymentMethodTypes.contains(.USBankAccount)
        let isLinkCardBrand = linkSettings?.linkMode?.isPantherPayment ?? false
        return isLinkCardBrand && !canAcceptACH
    }
}
