//
//  STPAnalyticsClient+BasicUI.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/24/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPPaymentContext {
    final class AnalyticsLogger {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let sessionID: String = UUID().uuidString.lowercased()
        var apiClient: STPAPIClient = .shared
        lazy var commonParameters: [String: Any] = {
            ["session_id": sessionID]
        }()

        func logLoadStarted() {
            analyticsClient.log(analytic: GenericAnalytic(event: .biLoadStarted, params: commonParameters), apiClient: apiClient)
        }

        func logLoadFinished(isSuccess: Bool, loadStartDate: Date) {
            let event: STPAnalyticEvent = isSuccess ? .biLoadSucceeded : .biLoadFailed
            let duration = Date().timeIntervalSince(loadStartDate)
            var params = commonParameters
            params["duration"] = duration
            let analytic = GenericAnalytic(event: event, params: params)
            analyticsClient.log(analytic: analytic, apiClient: apiClient)
        }

        func logPayment(status: STPPaymentStatus, paymentOption: STPPaymentOption, error: Error?) {
            let didSucceed: Bool
            switch status {
            case .userCancellation:
                // Don't send analytic for cancels
                return
            case .success:
                didSucceed = true
            case .error:
                didSucceed = false
            @unknown default:
                return
            }

            let event: STPAnalyticEvent
            let paymentMethodType: String
            switch paymentOption {
            case let paymentMethod as STPPaymentMethod:
                paymentMethodType = paymentMethod.type.identifier
                event = didSucceed ? .biPaymentCompleteSavedPMSuccess : .biPaymentCompleteSavedPMFailure
            case let params as STPPaymentMethodParams:
                paymentMethodType = params.type.identifier
                event = didSucceed ? .biPaymentCompleteNewPMSuccess : .biPaymentCompleteNewPMFailure
            case is STPApplePayPaymentOption:
                paymentMethodType = "apple_pay"
                event = didSucceed ? .biPaymentCompleteApplePaySuccess : .biPaymentCompleteApplePayFailure
            default:
                assertionFailure("Unknown payment option!")
                return
            }

            var params = commonParameters
            params["selected_lpm"] = paymentMethodType
            if STPAnalyticsClient.isSimulatorOrTest {
                params["is_development"] = true
            }
            if let error {
                params["error_message"] = error.makeSafeLoggingString()
            }

            let analytic = GenericAnalytic(event: event, params: params)
            analyticsClient.log(analytic: analytic, apiClient: apiClient)
        }
    }
}
