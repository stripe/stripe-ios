//
//  STPAnalyticsClient+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAnalyticsClient {

    // MARK: - Signup

    func logLinkSignupCheckboxChecked() {
        self.logPaymentSheetEvent(event: .linkSignupCheckboxChecked)
    }

    func logLinkSignupFlowPresented() {
        self.logPaymentSheetEvent(event: .linkSignupFlowPresented)
    }

    func logLinkSignupStart() {
        AnalyticsHelper.shared.startTimeMeasurement(.linkSignup)
        self.logPaymentSheetEvent(event: .linkSignupStart)
    }
    func logLinkInvalidSessionState(sessionState: PaymentSheetLinkAccount.SessionState) {
        let params = ["sessionState": sessionState.rawValue]
        self.logPaymentSheetEvent(event: .linkSignupFailureInvalidSessionState, params: params)
    }

    func logLinkSignupComplete() {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkSignup)
        self.logPaymentSheetEvent(event: .linkSignupComplete, duration: duration)
    }

    func logLinkSignupFailure(error: Error) {
        self.logPaymentSheetEvent(event: .linkSignupFailure, error: error)
    }

    func logLinkAccountLookupComplete(lookupResult: ConsumerSession.LookupResponse.ResponseType) {
        let params = ["lookupResult": lookupResult.analyticValue]
        self.logPaymentSheetEvent(event: .linkAccountLookupComplete, params: params)
    }

    func logLinkAccountLookupFailure(error: Error) {
        self.logPaymentSheetEvent(event: .linkAccountLookupFailure, error: error)
    }

    // MARK: - popup
    func logLinkPopupShow(sessionType: LinkSettings.PopupWebviewOption) {
        AnalyticsHelper.shared.startTimeMeasurement(.linkPopup)
        self.logLinkPopupEvent(event: .linkPopupShow, sessionType: sessionType)
    }

    func logLinkPopupSuccess(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logLinkPopupEvent(event: .linkPopupSuccess, duration: duration, sessionType: sessionType)
    }

    func logLinkPopupCancel(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logLinkPopupEvent(event: .linkPopupCancel, duration: duration, sessionType: sessionType)
    }

    func logLinkPopupSkipped() {
        logPaymentSheetEvent(event: .linkPopupSkipped)
    }

    func logLinkPopupError(error: Error?, sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logLinkPopupEvent(event: .linkPopupError, duration: duration, sessionType: sessionType, error: error)
    }

    func logLinkPopupLogout(sessionType: LinkSettings.PopupWebviewOption) {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkPopup)
        self.logLinkPopupEvent(event: .linkPopupLogout, duration: duration, sessionType: sessionType)
    }

    func logLinkPopupEvent(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        sessionType: LinkSettings.PopupWebviewOption,
        error: Error? = nil) {
            var params: [String: Any] = [:]
            if let error = error {
                params["error"] = error.localizedDescription
            }
            logPaymentSheetEvent(event: event,
                                 duration: duration,
                                 linkSessionType: sessionType,
                                 params: params)
        }

}
