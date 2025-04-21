//
//  STPAnalyticsClient+STPPaymentHandler.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 4/3/24.
//

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
        let status: STPPaymentHandlerActionStatus?
        let paymentMethodType: String?
        let paymentMethodID: String?
        let error: Error?

        var params: [String: Any] {
            var params: [String: Any] = error?.serializeForV1Analytics() ?? [:]
            params["intent_id"] = intentID
            params["status"] = status?.stringValue
            params["payment_method_type"] = paymentMethodType
            params["payment_method_id"] = paymentMethodID
            return params
        }
    }

    // MARK: - Confirm started

    func logConfirmSetupIntentStarted(setupIntentID: String?, confirmParams: STPSetupIntentConfirmParams) {
        let analytic = Analytic(
            event: .paymentHandlerConfirmStarted,
            intentID: setupIntentID,
            status: nil,
            paymentMethodType: confirmParams.paymentMethodType?.identifier,
            paymentMethodID: confirmParams.paymentMethodID,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logConfirmPaymentIntentStarted(paymentIntentID: String?, paymentParams: STPPaymentIntentParams) {
        let analytic = Analytic(
            event: .paymentHandlerConfirmStarted,
            intentID: paymentIntentID,
            status: nil,
            paymentMethodType: paymentParams.paymentMethodType?.identifier,
            paymentMethodID: paymentParams.paymentMethodId,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Confirm completed

    func logConfirmPaymentIntentCompleted(paymentIntentID: String?, paymentParams: STPPaymentIntentParams, status: STPPaymentHandlerActionStatus, error: Error?) {
        let analytic = Analytic(
            event: .paymentHandlerConfirmFinished,
            intentID: paymentIntentID,
            status: status,
            paymentMethodType: paymentParams.paymentMethodType?.identifier,
            paymentMethodID: paymentParams.paymentMethodId,
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logConfirmSetupIntentCompleted(setupIntentID: String?, confirmParams: STPSetupIntentConfirmParams, status: STPPaymentHandlerActionStatus, error: Error?) {
        let analytic = Analytic(
            event: .paymentHandlerConfirmFinished,
            intentID: setupIntentID,
            status: status,
            paymentMethodType: confirmParams.paymentMethodType?.identifier,
            paymentMethodID: confirmParams.paymentMethodID,
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Handle next action

    func logHandleNextActionStarted(intentID: String?, paymentMethod: STPPaymentMethod?) {
        let analytic = Analytic(
            event: .paymentHandlerHandleNextActionStarted,
            intentID: intentID,
            status: nil,
            paymentMethodType: paymentMethod?.type.identifier,
            paymentMethodID: paymentMethod?.stripeId,
            error: nil
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logHandleNextActionFinished(intentID: String?, paymentMethod: STPPaymentMethod?, status: STPPaymentHandlerActionStatus, error: Error?) {
        let analytic = Analytic(
            event: .paymentHandlerHandleNextActionFinished,
            intentID: intentID,
            status: status,
            paymentMethodType: paymentMethod?.type.identifier,
            paymentMethodID: paymentMethod?.stripeId,
            error: error
        )
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }
}
