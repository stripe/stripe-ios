//
//  CustomerSheet+API.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension CustomerSheet {
    func confirmIntent(
        intent: Intent,
        elementsSession: STPElementsSession,
        paymentOption: PaymentOption,
        confirmationChallenge: ConfirmationChallenge? = nil,
        completion: @escaping (InternalCustomerSheetResult) -> Void
    ) {
        CustomerSheet.confirm(intent: intent,
                              elementsSession: elementsSession,
                              paymentOption: paymentOption,
                              configuration: configuration,
                              paymentHandler: self.paymentHandler,
                              authenticationContext: self.bottomSheetViewController,
                              confirmationChallenge: confirmationChallenge,
                              completion: completion)
    }
    static func confirm(
        intent: Intent,
        elementsSession: STPElementsSession,
        paymentOption: PaymentOption,
        configuration: CustomerSheet.Configuration,
        paymentHandler: STPPaymentHandler,
        authenticationContext: STPAuthenticationContext,
        confirmationChallenge: ConfirmationChallenge? = nil,
        completion: @escaping (InternalCustomerSheetResult) -> Void
    ) {
        let paymentHandlerCompletion: (STPPaymentHandlerActionStatus, NSObject?, NSError?) -> Void =
            {
                (status, intent, error) in
                switch status {
                case .canceled:
                    completion(.canceled)
                case .failed:
                    // Hold a strong reference to paymentHandler
                    let unknownError = CustomerSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                case .succeeded:
                    completion(.completed(intent))
                @unknown default:
                    // Hold a strong reference to paymentHandler
                    let unknownError = CustomerSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                }
            }
        if case .new(let confirmParams) = paymentOption,
           case .setupIntent(let setupIntent) = intent {
            Task {
                confirmParams.setAllowRedisplayForCustomerSheet(elementsSession.savePaymentMethodConsentBehaviorForCustomerSheet())
                confirmParams.paymentMethodParams.radarOptions = await confirmationChallenge?.makeRadarOptions()
                confirmParams.paymentMethodParams.clientAttributionMetadata = STPClientAttributionMetadata(elementsSessionConfigId: elementsSession.configID)
                let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                setupIntentParams.paymentMethodParams = confirmParams.paymentMethodParams
                // Send CAM at the top-level of all requests in scope for consistency
                // Also send under payment_method_data because there are existing dependencies
                setupIntentParams.clientAttributionMetadata = confirmParams.paymentMethodParams.clientAttributionMetadata
                setupIntentParams.returnURL = configuration.returnURL
                setupIntentParams.additionalAPIParameters = [ "expand": ["payment_method"]]
                paymentHandler.confirmSetupIntent(
                    params: setupIntentParams,
                    authenticationContext: authenticationContext,
                    completion: { status, intent, error in
                        Task { await confirmationChallenge?.complete() }
                        paymentHandlerCompletion(status, intent, error)
                    })
            }
        } else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedCustomerSheetError,
                                              error: InternalError.invalidStateOnConfirmation)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            completion(.failed(error: CustomerSheetError.unknown(debugDescription: "Invalid state in confirmIntent")))
        }
    }
}
