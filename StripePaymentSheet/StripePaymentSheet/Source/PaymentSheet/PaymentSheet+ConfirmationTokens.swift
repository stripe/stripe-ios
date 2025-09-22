//
//  PaymentSheet+ConfirmationTokens.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/22/25.
//

import Foundation
@_spi(STP) import StripePayments

extension PaymentSheet {
    static func handleDeferredIntentConfirmation_confirmationToken(
        confirmType: ConfirmPaymentMethodType,
        configuration: PaymentElementConfiguration,
        intentConfig: PaymentSheet.IntentConfiguration,
        authenticationContext: STPAuthenticationContext,
        paymentHandler: STPPaymentHandler,
        isFlowController: Bool,
        allowsSetAsDefaultPM: Bool = false,
        elementsSession: STPElementsSession?,
        mandateData: STPMandateDataParams? = nil,
        radarOptions: STPRadarOptions? = nil,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        stpAssert(true, "Confirmation Tokens not yet implemented.")
    }
}
