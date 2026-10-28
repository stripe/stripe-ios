//
//  Checkout+Analytics.swift
//  StripePaymentSheet
//
//  Builds analytics payloads from Checkout configuration and confirmation flows.
//  Event names, timing, common session fields, and logging live in
//  CheckoutControllerAnalyticsHelper.
//
//  Configuration payload rules from the Metrics design:
//  https://docs.google.com/document/d/1CWglcOHR6I8cOWKjztPfnhnVG8axucpv-j5cWIoey7E/edit?tab=t.26k2d65sc5oi
//  - Keys: convert property names to snake_case (displaysMandateText -> displays_mandate_text).
//  - Booleans and safe enums: record the value.
//  - Lists of safe enums: record their string values, preserving order.
//  - PII, including merchant text and customer information: record only whether it is set.
//  - Appearance/customization: record the value, using the existing appearance serializer where available.
//  - Nested configuration: apply these rules recursively.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

extension CheckoutController {
    func confirmationAnalyticsParams(
        paymentOption: PaymentOption?,
        source: CheckoutControllerAnalyticsHelper.InvocationSource
    ) -> [String: Any] {
        var params: [String: Any] = [
            "invocation_source": source.rawValue,
            "active_link_session": LinkAccountContext.shared.account?.sessionState == .verified,
        ]
        params["selected_lpm"] = paymentOption?.paymentMethodTypeAnalyticsValue
        params["link_context"] = paymentOption?.linkContextAnalyticsValue
        params["link_ui"] = paymentOption?.linkUIAnalyticsValue
        if case .saved? = paymentOption {
            params["is_saved_payment_method"] = true
        } else {
            params["is_saved_payment_method"] = false
        }
        return params
    }

}

extension CheckoutController.Configuration {
    /// Serialize only presence flags and supported UI settings, never customer details or merchant identifiers.
    var checkoutAnalyticsPayload: [String: Any] {
        var params: [String: Any] = [
            "merchant_display_name": merchantDisplayName != nil,
            "defaults": [
                "billing_details": ["name": defaults.billingDetails?.name != nil, "address": defaults.billingDetails?.address != nil],
                "shipping_details": ["name": defaults.shippingDetails?.name != nil, "address": defaults.shippingDetails?.address != nil],
                "email": defaults.email != nil,
                "phone": defaults.phone != nil,
            ],
        ]
        params["payment_element"] = paymentElement?.checkoutAnalyticsPayload ?? NSNull()
        params["express_checkout_element"] = expressCheckoutElement?.checkoutAnalyticsPayload ?? NSNull()
        params["currency_selector_element"] = currencySelectorElement?.checkoutAnalyticsPayload ?? NSNull()
        params["shipping_address_element"] = shippingAddressElement?.checkoutAnalyticsPayload ?? NSNull()
        return params
    }
}

private extension PaymentElement.Configuration {
    var checkoutAnalyticsPayload: [String: Any] {
        var params: [String: Any] = [
            "apple_pay_config": applePayConfiguration != nil,
            "link_display": linkConfiguration?.display.rawValue ?? "automatic",
            "save_payment_method_opt_in_behavior": savePaymentMethodOptInBehavior.description,
            "appearance": appearance.analyticPayload,
            "remove_saved_payment_method_message": removeSavedPaymentMethodMessage != nil,
            "opens_card_scanner_automatically": opensCardScannerAutomatically,
            "terms_display": termsDisplay.analyticValue,
            "payment_method_layout": paymentMethodLayout.description,
            "displays_mandate_text": displaysMandateText,
        ]
        params["apple_pay_button_type"] = applePayConfiguration?.buttonType?.rawValue
        params["preferred_networks"] = preferredNetworks?.map { STPCardBrandUtilities.apiValue(from: $0) }.joined(separator: ", ")
        params["payment_method_order"] = paymentMethodOrder
        switch rowSelectionBehavior {
        case .default: params["row_selection_behavior"] = "default"
        case .immediateAction: params["row_selection_behavior"] = "immediate_action"
        }
        return params
    }
}

private extension ExpressCheckoutElement.Configuration {
    var checkoutAnalyticsPayload: [String: Any] {
        var params: [String: Any] = [
            "apple_pay_config": applePayConfiguration != nil,
            "apple_pay_visibility": applePayConfiguration == nil ? "never" : "automatic",
            "link_visibility": linkConfiguration.display.rawValue,
            "button_theme": appearance.buttonTheme.rawValue,
        ]
        params["apple_pay_button_type"] = applePayConfiguration?.buttonType?.rawValue
        params["max_columns"] = appearance.buttonLayout.maxColumns
        params["max_rows"] = appearance.buttonLayout.maxRows
        return params
    }
}

private extension ShippingAddressElement.Configuration {
    var checkoutAnalyticsPayload: [String: Any] {
        let defaults = Self()
        return [
            "title": title != defaults.title,
            "button_title": buttonTitle != defaults.buttonTitle,
            "appearance": [
                "font": appearance.font != defaults.appearance.font,
                "colors": appearance.colors != defaults.appearance.colors,
                "primary_button": appearance.primaryButton != defaults.appearance.primaryButton,
                "corner_radius": appearance.cornerRadius != defaults.appearance.cornerRadius,
                "border_width": appearance.borderWidth != defaults.appearance.borderWidth,
                "shadow": appearance.shadow != defaults.appearance.shadow,
                "text_field_insets": appearance.textFieldInsets != defaults.appearance.textFieldInsets,
                "form_insets": appearance.formInsets != defaults.appearance.formInsets,
            ],
        ]
    }
}

private extension CurrencySelectorElement.Configuration {
    var checkoutAnalyticsPayload: [String: Any] {
        let defaults = Self().appearance
        let labelContent: String
        switch appearance.labelContent {
        case .automatic: labelContent = "automatic"
        case .currencyCode: labelContent = "currency_code"
        case .amount: labelContent = "amount"
        }
        let colors = [appearance.border, appearance.background, appearance.selectedBackground, appearance.text, appearance.selectedText, appearance.textSecondary, appearance.danger]
        let defaultColors = [defaults.border, defaults.background, defaults.selectedBackground, defaults.text, defaults.selectedText, defaults.textSecondary, defaults.danger]
        let hasCustomColors = [UIUserInterfaceStyle.light, .dark].contains { style in
            let traits = UITraitCollection(userInterfaceStyle: style)
            return zip(colors, defaultColors).contains { $0.resolvedColor(with: traits) != $1.resolvedColor(with: traits) }
        }
        return [
            "appearance": [
                "content_vertical_padding": appearance.contentVerticalPadding != defaults.contentVerticalPadding,
                "corner_radius": appearance.cornerRadius != defaults.cornerRadius,
                "border_width": appearance.borderWidth != defaults.borderWidth,
                "font": appearance.font != defaults.font || appearance.sizeScaleFactor != defaults.sizeScaleFactor,
                "colors": hasCustomColors,
                "label_content": labelContent,
            ],
        ]
    }
}

extension CheckoutController.CheckoutConfirmationFlow {
    var analyticsPaymentOption: PaymentOption? {
        switch self {
        case .withoutPaymentMethod:
            return nil
        case .applePay:
            return .applePay
        case .link(let parameters):
            return .link(option: parameters.confirmOption)
        case .paymentMethod(let parameters, _):
            switch parameters.option {
            case .new(let params):
                return .new(confirmParams: params)
            case .saved(let paymentMethod, let params):
                return .saved(paymentMethod: paymentMethod, confirmParams: params)
            }
        }
    }
}
