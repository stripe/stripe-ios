//
//  STPApplePayContext+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

typealias PaymentSheetResultCompletionBlock = ((PaymentSheetResult) -> Void)

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension STPApplePayContext {

    static func create(intent: Intent,
                       merchantName: String,
                       configuration: PaymentSheet.ApplePayConfiguration,
                       completion: @escaping PaymentSheetResultCompletionBlock) -> STPApplePayContext? {
        /// A shim class; ApplePayContext expects a protocol/delegate, but PaymentSheet uses closures.
        class ApplePayContextClosureDelegate: NSObject, STPApplePayContextDelegate {
            let completion: PaymentSheetResultCompletionBlock
            /// Retain this class until Apple Pay completes
            var selfRetainer: ApplePayContextClosureDelegate?
            let clientSecret: String

            init(clientSecret: String, completion: @escaping PaymentSheetResultCompletionBlock) {
                self.completion = completion
                self.clientSecret = clientSecret
                super.init()
                self.selfRetainer = self
            }

            func applePayContext(_ context: STPApplePayContext,
                                 didCreatePaymentMethod paymentMethod: STPPaymentMethod,
                                 paymentInformation: PKPayment,
                                 completion: @escaping STPIntentClientSecretCompletionBlock) {
                completion(clientSecret, nil)
            }

            func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
                switch status {
                case .success:
                    completion(.completed)
                case .error:
                    completion(.failed(error: error!))
                case .userCancellation:
                    completion(.canceled)
                }
                selfRetainer = nil
            }
        }

        let paymentRequest: PKPaymentRequest
        switch intent {
        case .paymentIntent(let paymentIntent):
            paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: configuration.merchantId,
                                                          country: configuration.merchantCountryCode,
                                                          currency: paymentIntent.currency)
            let decimalAmount = NSDecimalNumber.stp_decimalNumber(withAmount: paymentIntent.amount, currency: paymentIntent.currency)
            paymentRequest.paymentSummaryItems = [
                PKPaymentSummaryItem(label: merchantName,
                                     amount: decimalAmount,
                                     type: .final),
            ]
        case .setupIntent:
            paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: configuration.merchantId,
                                                          country: configuration.merchantCountryCode,
                                                          currency: "USD") // currency is required but unused
            paymentRequest.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "\(merchantName)", amount: .one, type: .pending)
            ]
        }
        let delegate = ApplePayContextClosureDelegate(clientSecret: intent.clientSecret, completion: completion)
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
