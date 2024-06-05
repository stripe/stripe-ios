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
        var apiClient: STPAPIClient = .shared
        var product: String
        lazy var commonParameters: [String: Any] = {
            [
                "product": product,
            ]
        }()

        init<T: STPAnalyticsProtocol>(product: T.Type) {
            self.product = product.stp_analyticsIdentifier
        }

        // MARK: - Loading

        func logLoadStarted() {
            log(event: .biLoadStarted, params: [:])
        }

        func logLoadSucceeded(loadStartDate: Date, defaultPaymentOption: STPPaymentOption?) {
            let event: STPAnalyticEvent = .biLoadSucceeded
            let duration = Date().timeIntervalSince(loadStartDate)
            let defaultPaymentMethod: String = {
                guard let defaultPaymentOption else {
                    return "none"
                }
                switch defaultPaymentOption {
                case is STPApplePayPaymentOption:
                    return "apple_pay"
                case let defaultPaymentMethod as STPPaymentMethod:
                    return defaultPaymentMethod.type.identifier
                default:
                    assertionFailure()
                    return "unknown"
                }
            }()
            let params: [String: Any] = [
                "duration": duration,
                "selected_lpm": defaultPaymentMethod,
            ]
            log(event: event, params: params)
        }

        func logLoadFailed(loadStartDate: Date, error: Error) {
            let event: STPAnalyticEvent = .biLoadFailed
            let duration = Date().timeIntervalSince(loadStartDate)
            var params: [String: Any] = [
                "duration": duration,
            ]
            params.mergeAssertingOnOverwrites(error.serializeForV1Analytics())
            log(event: event, params: params)
        }

        // MARK: - Payment

        func logPayment(status: STPPaymentStatus, loadStartDate: Date?, paymentOption: STPPaymentOption, error: Error?) {
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

            var params: [String: Any] = ["selected_lpm": paymentMethodType]
            if let error {
                params.mergeAssertingOnOverwrites(error.serializeForV1Analytics())
            }
            if let loadStartDate {
                params["duration"] = Date().timeIntervalSince(loadStartDate)
            }

            log(event: event, params: params)
        }

        // MARK: - UI

        func logPaymentOptionsScreenAppeared() {
            log(event: .biOptionsShown, params: [:])
        }

        func logFormShown(paymentMethodType: STPPaymentMethodType) {
            let event = STPAnalyticEvent.biFormShown
            let params = ["selected_lpm": paymentMethodType]
            log(event: event, params: params)
        }

        /// - Parameter shownStartDate: The date when the form was first shown. This should never be nil.
        func logDoneButtonTapped(paymentMethodType: STPPaymentMethodType, shownStartDate: Date?) {
            let event = STPAnalyticEvent.biDoneButtonTapped

            var params: [String: Any] = [
                "selected_lpm": paymentMethodType,
            ]
            if let shownStartDate {
                let duration = Date().timeIntervalSince(shownStartDate)
                params["duration"] = duration
            } else if NSClassFromString("XCTest") == nil {
                assertionFailure("Shown start date should never be nil!")
            }

            log(event: event, params: params)
        }

        func logFormInteracted(paymentMethodType: STPPaymentMethodType) {
            log(event: .biFormInteracted, params: [
                "selected_lpm": paymentMethodType,
            ])
        }

        func logCardNumberCompleted() {
            log(event: .biCardNumberCompleted, params: [:])
        }

        // MARK: - Helpers

        private func log(event: STPAnalyticEvent, params: [String: Any]) {
            let analytic = GenericAnalytic(event: event, params: params.merging(commonParameters, uniquingKeysWith: { new, _ in
                assertionFailure("Constructing analytics parameters with duplicate keys")
                return new
            }))
            analyticsClient.log(analytic: analytic, apiClient: apiClient)
        }
    }
}
