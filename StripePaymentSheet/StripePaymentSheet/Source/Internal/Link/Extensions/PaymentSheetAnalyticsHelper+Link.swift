//
//  PaymentSheetAnalyticsHelper+Link.swift
//  StripePaymentSheet
//
//  Created by Jeremy Kelleher on 10/17/25.
//

import Foundation
@_spi(STP) import StripeCore

extension PaymentSheetAnalyticsHelper {

    func log(linkEvent: LinkAnalyticsV2Event) {
        analyticsClientV2.log(eventName: linkEvent.eventName, parameters: linkEvent.parameters)
    }

}

enum LinkAnalyticsV2Event {

    case inlineSignupShown(mode: LinkInlineSignupViewModel.Mode)

    var eventName: String {
        switch self {
        case .inlineSignupShown:
            "link_inline_signup_shown"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .inlineSignupShown(let mode):
            ["mode": mode.analyticsValue]
        }
    }

}

extension LinkInlineSignupViewModel.Mode {

    var analyticsValue: String {
        switch self {
        case .checkbox:
            "checkbox_default_unchecked"
        case .checkboxWithDefaultOptIn:
            "checkbox_default_checked"
        case .textFieldsOnlyEmailFirst:
            "text_fields_only_email_first"
        case .textFieldsOnlyPhoneFirst:
            "text_fields_only_phone_first"
        case .signupOptIn:
            "signup_opt_in"
        }
    }

}
