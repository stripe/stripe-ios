//
//  STPAnalyticsClient+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAnalyticsClient {

    func paymentSheetInitEventValue(isCustom: Bool, configuration: PaymentSheet.Configuration)
        -> STPAnalyticEvent
    {
        if isCustom {
            if configuration.customer == nil && configuration.applePay == nil {
                return .mcInitCustomDefault
            }

            if configuration.customer != nil && configuration.applePay == nil {
                return .mcInitCustomCustomer
            }

            if configuration.customer == nil && configuration.applePay != nil {
                return .mcInitCustomApplePay
            }

            return .mcInitCustomCustomerApplePay
        } else {
            if configuration.customer == nil && configuration.applePay == nil {
                return .mcInitCompleteDefault
            }

            if configuration.customer != nil && configuration.applePay == nil {
                return .mcInitCompleteCustomer
            }

            if configuration.customer == nil && configuration.applePay != nil {
                return .mcInitCompleteApplePay
            }

            return .mcInitCompleteCustomerApplePay
        }
    }

    func paymentSheetPaymentEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        success: Bool
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCustomNewPMSuccess : .mcPaymentCustomNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCustomSavedPMSuccess : .mcPaymentCustomSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCustomApplePaySuccess : .mcPaymentCustomApplePayFailure
            case .link:
                return success ? .mcPaymentCustomLinkSuccess : .mcPaymentCustomLinkFailure
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCompleteNewPMSuccess : .mcPaymentCompleteNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCompleteSavedPMSuccess : .mcPaymentCompleteSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCompleteApplePaySuccess : .mcPaymentCompleteApplePayFailure
            case .link:
                return success ? .mcPaymentCompleteLinkSuccess : .mcPaymentCompleteLinkFailure
            }
        }
    }

    func paymentSheetPaymentOptionSelectEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCustomNewPM
            case .savedPM:
                return .mcOptionSelectCustomSavedPM
            case .applePay:
                return .mcOptionSelectCustomApplePay
            case .link:
                return .mcOptionSelectCustomLink
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCompleteNewPM
            case .savedPM:
                return .mcOptionSelectCompleteSavedPM
            case .applePay:
                return .mcOptionSelectCompleteApplePay
            case .link:
                return .mcOptionSelectCompleteLink
            }
        }
    }

    // MARK: - Internal
    func logPaymentSheetEvent(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        linkEnabled: Bool? = nil,
        activeLinkSession: Bool? = nil,
        linkSessionType: LinkSettings.PopupWebviewOption? = nil,
        configuration: PaymentSheet.Configuration? = nil,
        currency: String? = nil,
        intentConfig: PaymentSheet.IntentConfiguration? = nil,
        error: Error? = nil,
        deferredIntentConfirmationType: DeferredIntentConfirmationType? = nil,
        paymentMethodTypeAnalyticsValue: String? = nil,
        linkContext: String? = nil,
        params: [String: Any] = [:],
        apiClient: STPAPIClient = .shared
    ) {
        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = duration
        additionalParams["link_enabled"] = linkEnabled
        additionalParams["active_link_session"] = activeLinkSession
        if let linkSessionType = linkSessionType {
            additionalParams["link_session_type"] = linkSessionType.rawValue
        }
        additionalParams["mpe_config"] = configuration?.analyticPayload
        additionalParams["locale"] = Locale.autoupdatingCurrent.identifier
        additionalParams["currency"] = currency
        additionalParams["is_decoupled"] = intentConfig != nil
        additionalParams["deferred_intent_confirmation_type"] = deferredIntentConfirmationType?.rawValue
        additionalParams["selected_lpm"] = paymentMethodTypeAnalyticsValue
        additionalParams["link_context"] = linkContext

        if let error {
            additionalParams.mergeAssertingOnOverwrites(error.serializeForV1Analytics())
        }

        for (param, param_value) in params {
            additionalParams[param] = param_value
        }
        let analytic = PaymentSheetAnalytic(event: event,
                                            additionalParams: additionalParams)
        log(analytic: analytic, apiClient: apiClient)
    }
}

extension PaymentSheetViewController.Mode {
    var analyticsValue: STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .addingNew:
            return .newPM
        case .selectingSaved:
            return .savedPM
        }
    }
}

/// Prevents accidentally reusing param names
///
struct PaymentSheetAnalytic: StripePayments.PaymentAnalytic {
    let event: STPAnalyticEvent
//    
//    let duration: TimeInterval?
//    let activeLinkSession: Bool?
//    let linkSessionType: LinkSettings.PopupWebviewOption?
//    let configuration: PaymentSheet.Configuration?
//    let currency: String?
//    let intentConfig: PaymentSheet.IntentConfiguration?
//    let error: Error?
//    let deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?
//    let paymentMethodTypeAnalyticsValue: String?
//    let linkContext: String?
    let additionalParams: [String: Any]
}

extension PaymentSheet.Configuration {

    /// Serializes the configuration into a safe dictionary containing no PII for analytics logging
    var analyticPayload: [String: Any] {
        var payload = [String: Any]()
        payload["allows_delayed_payment_methods"] = allowsDelayedPaymentMethods
        payload["apple_pay_config"] = applePay != nil
        payload["style"] = style.rawValue

        payload["customer"] = customer != nil
        payload["return_url"] = returnURL != nil
        payload["default_billing_details"] = defaultBillingDetails != PaymentSheet.BillingDetails()
        payload["save_payment_method_opt_in_behavior"] = savePaymentMethodOptInBehavior.description
        payload["appearance"] = appearance.analyticPayload
        payload["billing_details_collection_configuration"] = billingDetailsCollectionConfiguration.analyticPayload
        payload["preferred_networks"] = preferredNetworks?.map({ STPCardBrandUtilities.apiValue(from: $0) }).joined(separator: ", ")
        payload["payment_method_layout"] = paymentMethodLayout.description

        return payload
    }
}

extension PaymentSheet.SavePaymentMethodOptInBehavior {
    var description: String {
        switch self {
        case .automatic:
            return "automatic"
        case .requiresOptIn:
            return "requires_opt_in"
        case .requiresOptOut:
            return "requires_opt_out"
        }
    }
}

extension PaymentSheet.Appearance {
    var analyticPayload: [String: Bool] {
        var payload = [String: Bool]()
        payload["corner_radius"] = cornerRadius != PaymentSheet.Appearance.default.cornerRadius
        payload["border_width"] = borderWidth != PaymentSheet.Appearance.default.borderWidth
        payload["shadow"] = shadow != PaymentSheet.Appearance.default.shadow
        payload["font"] = font != PaymentSheet.Appearance.default.font
        payload["colors"] = colors != PaymentSheet.Appearance.default.colors
        payload["primary_button"] = primaryButton != PaymentSheet.Appearance.default.primaryButton
        // Convenience payload item to make querying high level appearance usage easier
        payload["usage"] = payload.values.contains(true)

        return payload
    }
}

extension PaymentSheet.BillingDetailsCollectionConfiguration {
    var analyticPayload: [String: Any] {
        return [
            "attach_defaults": attachDefaultsToPaymentMethod,
            "name": name.rawValue,
            "email": email.rawValue,
            "phone": phone.rawValue,
            "address": address.rawValue,
        ]
    }
}

extension PaymentSheet.PaymentMethodLayout {
    var description: String {
        switch self {
        case .horizontal:
            return "horizontal"
        case .vertical:
            return "vertical"
        }
    }
}

extension Intent {
    var analyticsValue: String {
        switch self {
        case .paymentIntent:
            return "payment_intent"
        case .setupIntent:
            return "setup_intent"
        case .deferredIntent(let intentConfig):
            switch intentConfig.mode {
            case .payment:
                return "deferred_payment_intent"
            case .setup:
                return "deferred_setup_intent"
            }
        }
    }
}
