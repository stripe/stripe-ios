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
        let error: Error?

        var params: [String: Any] {
            var params: [String: Any] = error?.serializeForV1Analytics() ?? [:]
            params["intent_id"] = intentID
            params["status"] = status?.stringValue
            params["payment_method_type"] = paymentMethodType
            return params
        }
    }

    // MARK: - Confirm started

    func logConfirmSetupIntentStarted(setupIntentID: String?, confirmParams: STPSetupIntentConfirmParams) {
        let analytic = Analytic(event: .paymentHandlerConfirmStarted, intentID: setupIntentID, status: nil, paymentMethodType: confirmParams.paymentMethodType?.identifier, error: nil)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logConfirmPaymentIntentStarted(paymentIntentID: String?, paymentParams: STPPaymentIntentParams) {
        let analytic = Analytic(event: .paymentHandlerConfirmStarted, intentID: paymentIntentID, status: nil, paymentMethodType: paymentParams.paymentMethodType?.identifier, error: nil)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Confirm completed

    func logConfirmPaymentIntentCompleted(paymentIntentID: String?, status: STPPaymentHandlerActionStatus, paymentMethodType: STPPaymentMethodType?, error: Error?) {
        let analytic = Analytic(event: .paymentHandlerConfirmFinished, intentID: paymentIntentID, status: status, paymentMethodType: paymentMethodType?.identifier, error: error)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logConfirmSetupIntentCompleted(setupIntentID: String?, status: STPPaymentHandlerActionStatus, paymentMethodType: STPPaymentMethodType?, error: Error?) {
        let analytic = Analytic(event: .paymentHandlerConfirmFinished, intentID: setupIntentID, status: status, paymentMethodType: paymentMethodType?.identifier, error: error)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    // MARK: - Handle next action

    func logHandleNextActionStarted(intentID: String?, paymentMethodType: STPPaymentMethodType?) {
        let analytic = Analytic(event: .paymentHandlerHandleNextActionStarted, intentID: intentID, status: nil, paymentMethodType: paymentMethodType?.identifier, error: nil)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }

    func logHandleNextActionFinished(intentID: String?, status: STPPaymentHandlerActionStatus, paymentMethodType: STPPaymentMethodType?, error: Error?) {
        let analytic = Analytic(event: .paymentHandlerHandleNextActionFinished, intentID: intentID, status: status, paymentMethodType: paymentMethodType?.identifier, error: error)
        analyticsClient.log(analytic: analytic, apiClient: apiClient)
    }
}
