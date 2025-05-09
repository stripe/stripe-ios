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

    /// The ordered payment method preference for this ElementsSession.
    let orderedPaymentMethodTypes: [STPPaymentMethodType]

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

    /// A map describing payment method types form specs.
    let paymentMethodSpecs: [[AnyHashable: Any]]?

    /// Card brand choice settings for the merchant.
    let cardBrandChoice: STPCardBrandChoice?

    let isApplePayEnabled: Bool

    /// An ordered list of external payment methods to display
    let externalPaymentMethods: [ExternalPaymentMethod]

    /// An ordered list of custom payment methods to display
    let customPaymentMethods: [CustomPaymentMethod]

    let customer: ElementsCustomer?

    /// A flag that indicates that this instance was created as a best-effort
    let isBackupInstance: Bool

    public let allResponseFields: [AnyHashable: Any]

    internal init(
        allResponseFields: [AnyHashable: Any],
        sessionID: String,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        merchantCountryCode: String?,
        linkSettings: LinkSettings?,
        experimentsData: ExperimentsData?,
        flags: [String: Bool],
        paymentMethodSpecs: [[AnyHashable: Any]]?,
        cardBrandChoice: STPCardBrandChoice?,
        isApplePayEnabled: Bool,
        externalPaymentMethods: [ExternalPaymentMethod],
        customPaymentMethods: [CustomPaymentMethod],
        customer: ElementsCustomer?,
        isBackupInstance: Bool = false
    ) {
        self.allResponseFields = allResponseFields
        self.sessionID = sessionID
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        self.countryCode = countryCode
        self.merchantCountryCode = merchantCountryCode
        self.linkSettings = linkSettings
        self.experimentsData = experimentsData
        self.flags = flags
        self.paymentMethodSpecs = paymentMethodSpecs
        self.cardBrandChoice = cardBrandChoice
        self.isApplePayEnabled = isApplePayEnabled
        self.externalPaymentMethods = externalPaymentMethods
        self.customPaymentMethods = customPaymentMethods
        self.customer = customer
        self.isBackupInstance = isBackupInstance
        super.init()
    }

    /// Returns a "best effort" STPElementsSessions object to be used as a last resort fallback if the endpoint failed to return a response or we failed to parse it.
    static func makeBackupElementsSession(with paymentIntent: STPPaymentIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: paymentIntent.allResponseFields,
            paymentMethodTypes: paymentIntent.paymentMethodTypes.map { STPPaymentMethodType.init(rawValue: $0.intValue) ?? .unknown }
        )
    }

    static func makeBackupElementsSession(with setupIntent: STPSetupIntent) -> STPElementsSession {
        return makeBackupElementsSession(
            allResponseFields: setupIntent.allResponseFields,
            paymentMethodTypes: setupIntent.paymentMethodTypes.map { STPPaymentMethodType.init(rawValue: $0.intValue) ?? .unknown }
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
            orderedPaymentMethodTypes: sortedPaymentMethodTypes,
            unactivatedPaymentMethodTypes: [],
            countryCode: nil,
            merchantCountryCode: nil,
            linkSettings: nil,
            experimentsData: nil,
            flags: [:],
            paymentMethodSpecs: nil,
            cardBrandChoice: STPCardBrandChoice.decodedObject(fromAPIResponse: [:]),
            isApplePayEnabled: true,
            externalPaymentMethods: [],
            customPaymentMethods: [],
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

        // Optional fields:
        let unactivatedPaymentMethodTypeStrings = response["unactivated_payment_method_types"] as? [String] ?? []
        let cardBrandChoice = STPCardBrandChoice.decodedObject(fromAPIResponse: response["card_brand_choice"] as? [AnyHashable: Any])
        let applePayPreference = response["apple_pay_preference"] as? String
        let isApplePayEnabled = applePayPreference != "disabled"
        let customer: ElementsCustomer? = {
            let customerDataKey = "customer"
            guard response[customerDataKey] != nil, !(response[customerDataKey] is NSNull) else {
                return nil
            }
            guard let customerJSON = response[customerDataKey] as? [AnyHashable: Any],
                  let decoded = ElementsCustomer.decoded(fromAPIResponse: customerJSON) else {
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
            orderedPaymentMethodTypes: paymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypeStrings.map({ STPPaymentMethod.type(from: $0) }),
            countryCode: paymentMethodPrefDict["country_code"] as? String,
            merchantCountryCode: response["merchant_country"] as? String,
            linkSettings: LinkSettings.decodedObject(
                fromAPIResponse: response["link_settings"] as? [AnyHashable: Any]
            ),
            experimentsData: ExperimentsData.decodedObject(
                fromAPIResponse: response["experiments_data"] as? [AnyHashable: Any]
            ),
            flags: response["flags"] as? [String: Bool] ?? [:],
            paymentMethodSpecs: response["payment_method_specs"] as? [[AnyHashable: Any]],
            cardBrandChoice: cardBrandChoice,
            isApplePayEnabled: isApplePayEnabled,
            externalPaymentMethods: externalPaymentMethods,
            customPaymentMethods: customPaymentMethods,
            customer: customer
        )
    }
}

// MARK: - Extensions
extension STPElementsSession {
    var isCardBrandChoiceEligible: Bool {
        return cardBrandChoice?.eligible ?? false
    }

    func allowsRemovalOfPaymentMethodsForPaymentSheet() -> Bool {
        var allowsRemovalOfPaymentMethods = false
        if let customerSession = customer?.customerSession {
            if customerSession.mobilePaymentElementComponent.enabled,
               let features = customerSession.mobilePaymentElementComponent.features {
                allowsRemovalOfPaymentMethods = features.paymentMethodRemove
            }
        } else {
            allowsRemovalOfPaymentMethods = true
        }
        return allowsRemovalOfPaymentMethods
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
                allowsRemovalOfPaymentMethods = features.paymentMethodRemove
            }
        } else {
            allowsRemovalOfPaymentMethods = true
        }
        return allowsRemovalOfPaymentMethods
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
