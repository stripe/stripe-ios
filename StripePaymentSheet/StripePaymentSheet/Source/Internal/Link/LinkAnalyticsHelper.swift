//
//  LinkAnalyticsHelper.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Analytics for one Link flow. Checkout context stays with the flow, not the shared Link account.
struct LinkAnalyticsHelper {
    private let analyticsClient: STPAnalyticsClient
    /// The Checkout Session ID attached to this flow's Link events. Nil for ordinary MPE and standalone Link.
    private let checkoutSessionID: String?

    init(analyticsClient: STPAnalyticsClient = .sharedClient, checkoutSessionID: String? = nil) {
        self.analyticsClient = analyticsClient
        self.checkoutSessionID = checkoutSessionID
    }

    // MARK: - Signup

    func logSignupCheckboxChecked() {
        analyticsClient.logPaymentSheetEvent(event: .linkSignupCheckboxChecked, checkoutSessionID: checkoutSessionID)
    }

    func logSignupFlowPresented() {
        analyticsClient.logPaymentSheetEvent(event: .linkSignupFlowPresented, checkoutSessionID: checkoutSessionID)
    }

    func logSignupStart() {
        AnalyticsHelper.shared.startTimeMeasurement(.linkSignup)
        analyticsClient.logPaymentSheetEvent(event: .linkSignupStart, checkoutSessionID: checkoutSessionID)
    }
    func logInvalidSessionState(sessionState: PaymentSheetLinkAccount.SessionState) {
        let params = ["sessionState": sessionState.rawValue]
        analyticsClient.logPaymentSheetEvent(event: .linkSignupFailureInvalidSessionState, checkoutSessionID: checkoutSessionID, params: params)
    }

    func logSignupComplete() {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkSignup)
        analyticsClient.logPaymentSheetEvent(event: .linkSignupComplete, checkoutSessionID: checkoutSessionID, duration: duration)
    }

    func logSignupFailure(error: Error) {
        var params: [String: Any] = [:]
        if let stripeError = error as? StripeError,
           case .apiError(let stripeAPIError) = stripeError,
           let message = stripeAPIError.message{
            params["error_message"] = message
        }
        analyticsClient.logPaymentSheetEvent(event: .linkSignupFailure, checkoutSessionID: checkoutSessionID, error: error, params: params)
    }

    func logSignupFailureAccountExists() {
        analyticsClient.logPaymentSheetEvent(event: .linkSignupFailureAccountExists, checkoutSessionID: checkoutSessionID)
    }

    func logCreatePaymentDetailsFailure(error: Error) {
        analyticsClient.logPaymentSheetEvent(event: .linkCreatePaymentDetailsFailure, checkoutSessionID: checkoutSessionID, error: error)
    }

    func logSharePaymentDetailsFailure(error: Error) {
        analyticsClient.logPaymentSheetEvent(event: .linkSharePaymentDetailsFailure, checkoutSessionID: checkoutSessionID, error: error)
    }

    func logAccountLookupComplete(lookupResult: ConsumerSession.LookupResponse.ResponseType) {
        let params = ["lookupResult": lookupResult.analyticValue]
        analyticsClient.logPaymentSheetEvent(event: .linkAccountLookupComplete, checkoutSessionID: checkoutSessionID, params: params)
    }

    func logAccountLookupFailure(error: Error) {
        analyticsClient.logPaymentSheetEvent(event: .linkAccountLookupFailure, checkoutSessionID: checkoutSessionID, error: error)
    }

    func logEmailSuggestionAccepted() {
        analyticsClient.logPaymentSheetEvent(event: .linkEmailSuggestionAccepted, checkoutSessionID: checkoutSessionID)
    }

    func logInlineSignupShown(mode: LinkInlineSignupViewModel.Mode) {
        let params = ["mode": mode.analyticsValue]
        analyticsClient.logPaymentSheetEvent(event: .linkInlineSignupShown, checkoutSessionID: checkoutSessionID, params: params)
    }

    // MARK: - 2FA

    private func verificationTypeParams(_ type: SupportedVerificationType?) -> [String: Any] {
        guard let type else { return [:] }
        return ["verification_type": type.rawValue]
    }

    func log2FAStart(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FAStart, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func log2FAStartFailure(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FAStartFailure, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func log2FAComplete(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FAComplete, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func log2FAFailure(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FAFailure, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func log2FACancel(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FACancel, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func log2FAResendCode(type: SupportedVerificationType?) {
        analyticsClient.logPaymentSheetEvent(event: .link2FAResendCode, checkoutSessionID: checkoutSessionID, params: verificationTypeParams(type))
    }

    func logBailedToWebFlow() {
        analyticsClient.logPaymentSheetEvent(event: .linkNativeBailed, checkoutSessionID: checkoutSessionID)
    }

    // MARK: - popup
    func logPopupShow(sessionType: LinkSettings.PopupWebviewOption) {
        AnalyticsHelper.shared.startTimeMeasurement(.linkPopup)
        self.logPopupEvent(event: .linkPopupShow, sessionType: sessionType)
    }

    func logPopupSuccess(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logPopupEvent(event: .linkPopupSuccess, duration: duration, sessionType: sessionType)
    }

    func logPopupCancel(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logPopupEvent(event: .linkPopupCancel, duration: duration, sessionType: sessionType)
    }

    func logPopupSkipped() {
        analyticsClient.logPaymentSheetEvent(event: .linkPopupSkipped, checkoutSessionID: checkoutSessionID)
    }

    func logPopupError(error: Error?, returnURL: URL?, sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        var params: [String: Any] = [:]
        if let redactedURL = LinkPopupURLParser.redactedURLForLogging(url: returnURL) {
            params["returnURL"] = redactedURL
        }
        if let error = error {
            params["error"] = error.localizedDescription
        }
        analyticsClient.logPaymentSheetEvent(event: .linkPopupError, checkoutSessionID: checkoutSessionID, duration: duration, linkSessionType: sessionType, params: params)
    }

    func logPopupLogout(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logPopupEvent(event: .linkPopupLogout, duration: duration, sessionType: sessionType)
    }

    private func logPopupEvent(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        sessionType: LinkSettings.PopupWebviewOption
    ) {
        analyticsClient.logPaymentSheetEvent(
            event: event,
            checkoutSessionID: checkoutSessionID,
            duration: duration,
            linkSessionType: sessionType
        )
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
