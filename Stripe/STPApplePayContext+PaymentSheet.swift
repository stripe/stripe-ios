//
//  STPApplePayContext+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPApplePayContext {

    static func create(paymentIntent: STPPaymentIntent,
                       merchantName: String,
                       configuration: PaymentSheet.ApplePayConfiguration,
                       completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock) -> STPApplePayContext? {
        /// A shim class; ApplePayContext expects a protocol/delegate, but PaymentSheet uses closures.
        class ApplePayContextClosureDelegate: NSObject, STPApplePayContextDelegate {
            let completion: STPPaymentHandlerActionPaymentIntentCompletionBlock
            /// Retain this class until Apple Pay completes
            var selfRetainer: ApplePayContextClosureDelegate?
            let paymentIntent: STPPaymentIntent

            init(paymentIntent: STPPaymentIntent, completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock) {
                self.completion = completion
                self.paymentIntent = paymentIntent
                super.init()
                self.selfRetainer = self
            }
            func applePayContext(_ context: STPApplePayContext,
                                 didCreatePaymentMethod paymentMethod: STPPaymentMethod,
                                 paymentInformation: PKPayment,
                                 completion: @escaping STPIntentClientSecretCompletionBlock) {
                completion(paymentIntent.clientSecret, nil)
            }

            func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
                let error = error as NSError?
                switch status {
                case .success:
                    completion(.succeeded, paymentIntent, nil)
                case .error:
                    completion(.failed, paymentIntent, error)
                case .userCancellation:
                    completion(.canceled, paymentIntent, error)
                }
                selfRetainer = nil
            }
        }

        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: configuration.merchantId,
                                                      country: configuration.merchantCountryCode,
                                                      currency: paymentIntent.currency)
        let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: paymentIntent.amount, currency: paymentIntent.currency)
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: merchantName,
                                 amount: decimalAmount,
                                 type: .final),
        ]
        let delegate = ApplePayContextClosureDelegate(paymentIntent: paymentIntent, completion: completion)
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: delegate) {
            return applePayContext
        } else {
            // Delegate only deallocs when Apple Pay completes
            // Since Apple Pay failed to start, nil it out now
            delegate.selfRetainer = nil
            return nil
        }
    }
}
