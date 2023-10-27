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
        paymentOption: PaymentOption,
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
                    let unknownError = CustomerSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(self.paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                case .succeeded:
                    completion(.completed(intent))
                @unknown default:
                    // Hold a strong reference to paymentHandler
                    let unknownError = CustomerSheetError.unknown(debugDescription: "STPPaymentHandler failed without an error: \(self.paymentHandler.description)")
                    completion(.failed(error: error ?? unknownError))
                }
            }
        if case .new(let confirmParams) = paymentOption,
           case .setupIntent(let setupIntent) = intent {
            let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
            setupIntentParams.paymentMethodParams = confirmParams.paymentMethodParams
            setupIntentParams.returnURL = configuration.returnURL
            setupIntentParams.additionalAPIParameters = [ "expand": ["payment_method"]]
            paymentHandler.confirmSetupIntent(
                setupIntentParams,
                with: self.bottomSheetViewController,
                completion: paymentHandlerCompletion)
        } else {
            completion(.failed(error: CustomerSheetError.unknown(debugDescription: "Invalid state in confirmIntent")))
        }
    }
}
