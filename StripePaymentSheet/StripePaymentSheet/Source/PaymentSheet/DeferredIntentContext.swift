//
//  DeferredIntentContext.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/3/23.
//

import Foundation
import StripePayments

class DeferredIntentContext {
    let configuration: PaymentSheet.Configuration
    let intentConfig: PaymentSheet.IntentConfiguration
    let paymentOption: PaymentOption
    let authenticationContext: STPAuthenticationContext
    let paymentHandler: STPPaymentHandler
    let completion: PaymentSheetResultCompletionBlock

    var isServerSideConfirmation: Bool {
        return intentConfig.confirmHandlerForServerSideConfirmation != nil
    }

    init(configuration: PaymentSheet.Configuration,
         intentConfig: PaymentSheet.IntentConfiguration,
         paymentOption: PaymentOption,
         authenticationContext: STPAuthenticationContext,
         paymentHandler: STPPaymentHandler,
         completion: @escaping PaymentSheetResultCompletionBlock) {
        self.configuration = configuration
        self.intentConfig = intentConfig
        self.paymentOption = paymentOption
        self.authenticationContext = authenticationContext
        self.paymentHandler = paymentHandler
        self.completion = completion
    }
}
