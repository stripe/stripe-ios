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
    // MARK: - Log events
    func logPaymentSheetInitialized(
        isCustom: Bool = false, configuration: PaymentSheet.Configuration, intentConfig: PaymentSheet.IntentConfiguration?
    ) {
        logPaymentSheetEvent(event: paymentSheetInitEventValue(
                             isCustom: isCustom,
                             configuration: configuration),
                             configuration: configuration,
                             intentConfig: intentConfig)
    }

    func logPaymentSheetPayment(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        result: PaymentSheetResult,
        linkEnabled: Bool,
        activeLinkSession: Bool,
        linkSessionType: LinkSettings.PopupWebviewOption?,
        currency: String?,
        intentConfig: PaymentSheet.IntentConfiguration? = nil,
        deferredIntentConfirmationType: DeferredIntentConfirmationType?,
        paymentMethodTypeAnalyticsValue: String? = nil,
        error: Error? = nil
    ) {
        var success = false
        switch result {
        case .canceled:
            // We don't report these to analytics, bail out.
            return
        case .failed:
            success = false
        case .completed:
            success = true
        }

        logPaymentSheetEvent(
            event: paymentSheetPaymentEventValue(
                isCustom: isCustom,
                paymentMethod: paymentMethod,
                success: success
            ),
            duration: AnalyticsHelper.shared.getDuration(for: .checkout),
            linkEnabled: linkEnabled,
            activeLinkSession: activeLinkSession,
            linkSessionType: linkSessionType,
            currency: currency,
            intentConfig: intentConfig,
            error: error,
            deferredIntentConfirmationType: deferredIntentConfirmationType,
            paymentMethodTypeAnalyticsValue: paymentMethodTypeAnalyticsValue
        )
    }

    func logPaymentSheetShow(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        linkEnabled: Bool,
        activeLinkSession: Bool,
        currency: String?,
        intentConfig: PaymentSheet.IntentConfiguration? = nil
    ) {
        AnalyticsHelper.shared.startTimeMeasurement(.checkout)
        logPaymentSheetEvent(
            event: paymentSheetShowEventValue(isCustom: isCustom, paymentMethod: paymentMethod),
            linkEnabled: linkEnabled,
            activeLinkSession: activeLinkSession,
            currency: currency,
            intentConfig: intentConfig
        )
    }

    func logPaymentSheetPaymentOptionSelect(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration? = nil
    ) {
        logPaymentSheetEvent(event: paymentSheetPaymentOptionSelectEventValue(
                             isCustom: isCustom,
                             paymentMethod: paymentMethod),
                             intentConfig: intentConfig)
    }

    enum DeferredIntentConfirmationType: String {
        case server = "server"
        case client = "client"
        case none = "none"
    }

    // MARK: - String builders
    enum AnalyticsPaymentMethodType: String {
        case newPM = "newpm"
        case savedPM = "savedpm"
        case applePay = "applepay"
        case link = "link"
    }

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

    func paymentSheetShowEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return .mcShowCustomNewPM
            case .savedPM:
                return .mcShowCustomSavedPM
            case .applePay:
                return .mcShowCustomApplePay
            case .link:
                return .mcShowCustomLink
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return .mcShowCompleteNewPM
            case .savedPM:
                return .mcShowCompleteSavedPM
            case .applePay:
                return .mcShowCompleteApplePay
            case .link:
                return .mcShowCompleteLink
            }
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
        params: [String: Any] = [:]
    ) {
        var additionalParams = [:] as [String: Any]
        if isSimulatorOrTest {
            additionalParams["is_development"] = true
        }

        additionalParams["duration"] = duration
        additionalParams["link_enabled"] = linkEnabled
        additionalParams["active_link_session"] = activeLinkSession
        if let linkSessionType = linkSessionType {
            additionalParams["link_session_type"] = linkSessionType.rawValue
        }
        additionalParams["session_id"] = AnalyticsHelper.shared.sessionID
        additionalParams["mpe_config"] = configuration?.analyticPayload
        additionalParams["locale"] = Locale.autoupdatingCurrent.identifier
        additionalParams["currency"] = currency
        additionalParams["is_decoupled"] = intentConfig != nil
        additionalParams["deferred_intent_confirmation_type"] = deferredIntentConfirmationType?.rawValue
        additionalParams["selected_lpm"] = paymentMethodTypeAnalyticsValue
        if let error = error as? PaymentSheetError {
            additionalParams["error_message"] = error.safeLoggingString
        } else if let error = error as? NSError, let code = STPErrorCode(rawValue: error.code) {
            // attempt log PII safe server error messages
            additionalParams["error_message"] = code.description
        }

        for (param, param_value) in params {
            additionalParams[param] = param_value
        }
        let analytic = PaymentSheetAnalytic(event: event,
                                            productUsage: productUsage,
                                            additionalParams: additionalParams)

        log(analytic: analytic)
    }

    var isSimulatorOrTest: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return NSClassFromString("XCTest") != nil
        #endif
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

extension PaymentSheetFlowControllerViewController.Mode {
    var analyticsValue: STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .addingNew:
            return .newPM
        case .selectingSaved:
            return .savedPM
        }
    }
}

extension SavedPaymentOptionsViewController.Selection {
    var analyticsValue: STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .add:
            return .newPM
        case .saved:
            return .savedPM
        case .applePay:
            return .applePay
        case .link:
            return .link
        }
    }
}

extension PaymentSheet.PaymentOption {
    var analyticsValue: STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .applePay:
            return .applePay
        case .new, .externalPayPal:
            return .newPM
        case .saved:
            return .savedPM
        case .link:
            return .link
        }
    }
}

struct PaymentSheetAnalytic: StripePayments.PaymentAnalytic {
    let event: STPAnalyticEvent
    let productUsage: Set<String>
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
