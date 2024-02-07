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
                             intentConfig: intentConfig,
                             apiClient: configuration.apiClient)
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
        error: Error? = nil,
        apiClient: STPAPIClient
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
            paymentMethodTypeAnalyticsValue: paymentMethodTypeAnalyticsValue,
            apiClient: apiClient
        )
    }

    func logPaymentSheetShow(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        linkEnabled: Bool,
        activeLinkSession: Bool,
        currency: String?,
        intentConfig: PaymentSheet.IntentConfiguration? = nil,
        apiClient: STPAPIClient
    ) {
        if !isCustom {
            AnalyticsHelper.shared.startTimeMeasurement(.checkout)
        }
        logPaymentSheetEvent(
            event: paymentSheetShowEventValue(isCustom: isCustom, paymentMethod: paymentMethod),
            linkEnabled: linkEnabled,
            activeLinkSession: activeLinkSession,
            currency: currency,
            intentConfig: intentConfig,
            apiClient: apiClient
        )
    }

    func logPaymentSheetPaymentOptionSelect(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        intentConfig: PaymentSheet.IntentConfiguration? = nil,
        apiClient: STPAPIClient
    ) {
        logPaymentSheetEvent(event: paymentSheetPaymentOptionSelectEventValue(
                             isCustom: isCustom,
                             paymentMethod: paymentMethod),
                             intentConfig: intentConfig,
                             apiClient: apiClient
        )
    }

    func logPaymentSheetLoadSucceeded(loadingStartDate: Date, defaultPaymentMethod: SavedPaymentOptionsViewController.Selection?) {
        let defaultPaymentMethodAnalyticsValue: String = {
            switch defaultPaymentMethod {
            case .applePay:
                return "apple_pay"
            case .link:
                return "link"
            case .saved(paymentMethod: let paymentMethod):
                return paymentMethod.type.identifier
            case nil:
                return "none"
            case .add:
                assertionFailure("Caller should ensure that default payment method is `nil` in this case.")
                return "none"
            }
        }()
        logPaymentSheetEvent(
            event: .paymentSheetLoadSucceeded,
            duration: Date().timeIntervalSince(loadingStartDate),
            params: ["selected_lpm": defaultPaymentMethodAnalyticsValue]
        )
    }

    func logPaymentSheetFormShown(paymentMethodTypeIdentifier: String, apiClient: STPAPIClient) {
        AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = false
        AnalyticsHelper.shared.startTimeMeasurement(.formShown)
        logPaymentSheetEvent(event: .paymentSheetFormShown, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier, apiClient: apiClient)
    }

    func logPaymentSheetFormInteracted(paymentMethodTypeIdentifier: String) {
        if !AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown {
            AnalyticsHelper.shared.didSendPaymentSheetFormInteractedEventAfterFormShown = true
            logPaymentSheetEvent(event: .paymentSheetFormInteracted, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier)
        }
    }

    func logPaymentSheetConfirmButtonTapped(paymentMethodTypeIdentifier: String) {
        let duration = AnalyticsHelper.shared.getDuration(for: .formShown)
        logPaymentSheetEvent(event: .paymentSheetConfirmButtonTapped, duration: duration, paymentMethodTypeAnalyticsValue: paymentMethodTypeIdentifier)
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
        params: [String: Any] = [:],
        apiClient: STPAPIClient = .shared
    ) {
        var additionalParams = [:] as [String: Any]
        if Self.isSimulatorOrTest {
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

        if let error {
            additionalParams["error_message"] = makeSafeLoggingString(from: error)
        }

        for (param, param_value) in params {
            additionalParams[param] = param_value
        }
        let analytic = PaymentSheetAnalytic(event: event,
                                            additionalParams: additionalParams)
        log(analytic: analytic, apiClient: apiClient)
    }

    /// Returns a string describing the provided error that doesn't contain PII and is suitable for logging.
    func makeSafeLoggingString(from error: Error) -> String {
        let error = error as NSError
        if let error = error as? PaymentSheetError {
            return error.safeLoggingString
        } else {
            return error.makeSafeLoggingString()
        }
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
        case .new, .external:
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
