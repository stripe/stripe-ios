//
//  STPAnalyticsClient+STPPaymentHandler.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 4/3/24.
//

import Foundation
@_spi(STP) import StripeCore

extension STPPaymentHandlerActionStatus {
    var stringValue: String {
        switch self {
        case .canceled:
            return "canceled"
        case .failed:
            return "failed"
        case .succeeded:
            return "succeeded"
        }
    }
}

extension STPPaymentHandler {
    struct Analytic: StripeCore.Analytic {
        let event: StripeCore.STPAnalyticEvent
        let intentID: String?
        let actionID: String?
        let status: STPPaymentHandlerActionStatus?
        let paymentMethodType: String?
        let paymentMethodID: String?
        let duration: TimeInterval?
        let error: Error?

        var params: [String: Any] {
            var params: [String: Any] = error?.serializeForV1Analytics() ?? [:]
            params["action_id"] = actionID
            params["intent_id"] = intentID
            params["status"] = status?.stringValue
            params["payment_method_type"] = paymentMethodType
            params["payment_method_id"] = paymentMethodID
            params["duration"] = duration
            return params
        }
    }

    // MARK: - Confirm started

    func logConfirmSetupIntentStarted(setupIntentID: String?, confirmParams: STPSetupIntentConfirmParams) {
        startTime = Date()
        let analytic = Analytic(
            event: .paymentHandlerConfirmStarted,
            intentID: setupIntentID,
            actionID: actionID,
            status: nil,
            paymentMethodType: confirmParams.paymentMethodType?.identifier,
            paymentMethodID: confirmParams.paymentMethodID,
            duration: nil,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logConfirmPaymentIntentStarted(paymentIntentID: String?, paymentParams: STPPaymentIntentConfirmParams) {
        startTime = Date()
        let analytic = Analytic(
            event: .paymentHandlerConfirmStarted,
            intentID: paymentIntentID,
            actionID: actionID,
            status: nil,
            paymentMethodType: paymentParams.paymentMethodType?.identifier,
            paymentMethodID: paymentParams.paymentMethodId,
            duration: nil,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Confirm completed

    func logConfirmPaymentIntentCompleted(paymentIntentID: String?, paymentParams: STPPaymentIntentConfirmParams, status: STPPaymentHandlerActionStatus, error: Error?) {
        stpAssert(startTime != nil)
        let analytic = Analytic(
            event: .paymentHandlerConfirmFinished,
            intentID: paymentIntentID,
            actionID: actionID,
            status: status,
            paymentMethodType: paymentParams.paymentMethodType?.identifier,
            paymentMethodID: paymentParams.paymentMethodId,
            duration: startTime.map { Date().timeIntervalSince($0) },
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
        startTime = nil
    }

    func logConfirmSetupIntentCompleted(setupIntentID: String?, confirmParams: STPSetupIntentConfirmParams, status: STPPaymentHandlerActionStatus, error: Error?) {
        stpAssert(startTime != nil)
        let analytic = Analytic(
            event: .paymentHandlerConfirmFinished,
            intentID: setupIntentID,
            actionID: actionID,
            status: status,
            paymentMethodType: confirmParams.paymentMethodType?.identifier,
            paymentMethodID: confirmParams.paymentMethodID,
            duration: startTime.map { Date().timeIntervalSince($0) },
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
        startTime = nil
    }

    // MARK: - Handle next action

    func logHandleNextActionStarted(intentID: String?, paymentMethod: STPPaymentMethod?) {
        startTime = Date()
        let analytic = Analytic(
            event: .paymentHandlerHandleNextActionStarted,
            intentID: intentID,
            actionID: actionID,
            status: nil,
            paymentMethodType: paymentMethod?.type.identifier,
            paymentMethodID: paymentMethod?.stripeId,
            duration: nil,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logHandleNextActionFinished(intentID: String?, paymentMethod: STPPaymentMethod?, status: STPPaymentHandlerActionStatus, error: Error?) {
        stpAssert(startTime != nil)
        let analytic = Analytic(
            event: .paymentHandlerHandleNextActionFinished,
            intentID: intentID,
            actionID: actionID,
            status: status,
            paymentMethodType: paymentMethod?.type.identifier,
            paymentMethodID: paymentMethod?.stripeId,
            duration: startTime.map { Date().timeIntervalSince($0) },
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
        startTime = nil
    }

    // MARK: - URL Redirect next action

    enum URLRedirectNextActionRedirectType: String {
        /// ASWebAuthenticationSession opened
        case ASWebAuthenticationSession = "ASWAS"
        /// SFSafariViewController opened
        case SFSafariViewController = "SFVC"
        /// Native app opened
        case nativeApp = "native_app"
    }

    enum URLRedirectNextActionReturnType: String {
        /// ASWebAuthenticationSession closed
        case ASWebAuthenticationSession = "ASWAS"
        /// SFSafariViewController closed
        case SFSafariViewController = "SFVC"
        /// Customer returned to app automatically via something (Safari, another app, etc) opening return url
        case returnURLCallback = "return_url"
        /// Customer returned to app by foregrounding it manually, only possible when native app is opened
        case appForegrounded = "app_foregrounded"
    }

    func logURLRedirectNextActionStarted(redirectType: URLRedirectNextActionRedirectType) {
        let analytic = GenericAnalytic(event: .urlRedirectNextAction, params: [
            "redirect_type": redirectType.rawValue,
            "action_id": actionID as Any,
        ])
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logURLRedirectNextActionFinished(returnType: URLRedirectNextActionReturnType) {
        let analytic = GenericAnalytic(event: .urlRedirectNextActionCompleted, params: [
            "redirect_type": returnType.rawValue,
            "action_id": actionID as Any,
        ])
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }
}
