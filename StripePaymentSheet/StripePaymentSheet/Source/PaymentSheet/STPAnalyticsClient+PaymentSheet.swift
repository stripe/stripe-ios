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
    /// ⚠️ Deprecated - use `PaymentSheetAnalyticsHelper` if you are actually a PaymentSheet analytic so that you can send all the params common to PaymentSheet analytics. 
    func logPaymentSheetEvent(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        linkSessionType: LinkSettings.PopupWebviewOption? = nil,
        error: Error? = nil,
        paymentMethodTypeAnalyticsValue: String? = nil,
        params: [String: Any] = [:],
        apiClient: STPAPIClient = .shared
    ) {
        var additionalParams = [:] as [String: Any]
        additionalParams["duration"] = duration
        if let linkSessionType {
            additionalParams["link_session_type"] = linkSessionType.rawValue
        }
        additionalParams["selected_lpm"] = paymentMethodTypeAnalyticsValue

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

struct PaymentSheetAnalytic: StripePayments.PaymentAnalytic {
    let event: STPAnalyticEvent
    let additionalParams: [String: Any]
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
    var analyticPayload: [String: Any] {
        var payload = [String: Any]()
        payload["corner_radius"] = cornerRadius != PaymentSheet.Appearance.default.cornerRadius
        payload["border_width"] = borderWidth != PaymentSheet.Appearance.default.borderWidth
        payload["shadow"] = shadow != PaymentSheet.Appearance.default.shadow
        payload["font"] = font != PaymentSheet.Appearance.default.font
        payload["colors"] = colors != PaymentSheet.Appearance.default.colors
        payload["primary_button"] = primaryButton != PaymentSheet.Appearance.default.primaryButton
        // Convenience payload item to make querying high level appearance usage easier
        payload["usage"] = payload.values.contains(where: { value in
            if let boolValue = value as? Bool {
                return boolValue == true
            }
            return false
        })
        payload["embedded_payment_element"] = embeddedPaymentElement.analyticPayload
        return payload
    }
}

extension PaymentSheet.Appearance.EmbeddedPaymentElement {
    static let `default` = PaymentSheet.Appearance.EmbeddedPaymentElement()

    var analyticPayload: [String: Any] {
        var payload = [String: Any]()
        payload["row_style"] = row.style.analyticsValue
        payload["row"] = row != PaymentSheet.Appearance.EmbeddedPaymentElement.default.row
        return payload
    }
}

extension EmbeddedPaymentElement.Configuration.FormSheetAction {
    var analyticValue: String {
        switch self {
        case .confirm:
            return "confirm"
        case .`continue`:
            return "continue"
        }
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
        case .automatic:
            return "automatic"
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

extension PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style {
    var analyticsValue: String {
        switch self {
        case .flatWithRadio:
            return "flat_with_radio"
        case .floatingButton:
            return "floating_button"
        case .flatWithCheckmark:
            return "flat_with_checkmark"
        }
    }
}
