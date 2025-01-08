//
//  PaymentSheetDeferredValidator.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments
struct PaymentSheetDeferredValidator {
    /// Note: We don't validate amount (for any payment method) because there are use cases where the amount can change slightly between PM collection and confirmation.
    static func validate(paymentIntent: STPPaymentIntent,
                         intentConfiguration: PaymentSheet.IntentConfiguration,
                         paymentMethod: STPPaymentMethod,
                         isFlowController: Bool) throws {
        guard case let .payment(_, currency, setupFutureUsage, captureMethod) = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        guard paymentIntent.currency.uppercased() == currency.uppercased() else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent currency (\(paymentIntent.currency.uppercased())) does not match the PaymentSheet.IntentConfiguration currency (\(currency.uppercased())).")
        }
        guard paymentIntent.setupFutureUsage == setupFutureUsage else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent setupFutureUsage (\(paymentIntent.setupFutureUsage)) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
        }
        guard paymentIntent.captureMethod == captureMethod else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent captureMethod (\(paymentIntent.captureMethod)) does not match the PaymentSheet.IntentConfiguration amount (\(captureMethod)).")
        }
        try validatePaymentMethod(intentPaymentMethod: paymentIntent.paymentMethod, paymentMethod: paymentMethod)
        /*
         Manual confirmation is only available using FlowController because merchants own the final step of confirmation.
         Showing a successful payment in the complete flow may be misleading when merchants still need to do a final confirmation which could fail e.g., bad network
         */
        if !isFlowController && paymentIntent.confirmationMethod == .manual {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent confirmationMethod (\(paymentIntent.confirmationMethod)) can only be used with PaymentSheet.FlowController.")
        }
    }

    static func validate(setupIntent: STPSetupIntent,
                         intentConfiguration: PaymentSheet.IntentConfiguration,
                         paymentMethod: STPPaymentMethod) throws {
        guard case let .setup(_, setupFutureUsage) = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
        }
        guard setupIntent.usage == setupFutureUsage else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your SetupIntent usage (\(setupIntent.usage)) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
        }
        try validatePaymentMethod(intentPaymentMethod: setupIntent.paymentMethod, paymentMethod: paymentMethod)
    }

    static func validatePaymentMethod(intentPaymentMethod: STPPaymentMethod?, paymentMethod: STPPaymentMethod) throws {
        guard let intentPaymentMethod = intentPaymentMethod else { return }
        guard intentPaymentMethod.stripeId == paymentMethod.stripeId else {
            if intentPaymentMethod.type == paymentMethod.type {
                // Payment methods of type card and us_bank_account can be cloned, leading to mismatched pm ids, but their fingerprints should still match
                switch paymentMethod.type {
                case .card:
                    try validateFingerprint(intentFingerprint: intentPaymentMethod.card?.fingerprint, fingerprint: paymentMethod.card?.fingerprint)
                    return
                case .USBankAccount:
                    try validateFingerprint(intentFingerprint: intentPaymentMethod.usBankAccount?.fingerprint, fingerprint: paymentMethod.usBankAccount?.fingerprint)
                    return
                default:
                    break
                }
            }
            let errorMessage = """
                \nThere is a mismatch between the payment method ID on your Intent: \(intentPaymentMethod.stripeId) and the payment method passed into the `confirmHandler`: \(paymentMethod.stripeId).

                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """
            let errorAnalytic = ErrorAnalytic(event: .paymentSheetDeferredIntentPaymentMethodMismatch, error: PaymentSheetError.unknown(debugDescription: errorMessage), additionalNonPIIParams: ["field": "payment method ID"])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            throw PaymentSheetError.deferredIntentValidationFailed(message: errorMessage)
        }
    }

    static func validateFingerprint(intentFingerprint: String?, fingerprint: String?) throws {
        guard let intentFingerprint = intentFingerprint else { return }
        guard let fingerprint = fingerprint else { return }
        guard intentFingerprint == fingerprint else {
            let errorMessage = """
                \nThere is a mismatch between the fingerprint of the payment method on your Intent: \(intentFingerprint) and the fingerprint of the payment method passed into the `confirmHandler`: \(fingerprint).

                To resolve this issue, you can:
                1. Create a new Intent each time before you call the `confirmHandler`, or
                2. Update the existing Intent with the desired `paymentMethod` before calling the `confirmHandler`.
            """
            let errorAnalytic = ErrorAnalytic(event: .paymentSheetDeferredIntentPaymentMethodMismatch, error: PaymentSheetError.unknown(debugDescription: errorMessage), additionalNonPIIParams: ["field": "fingerprint"])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            throw PaymentSheetError.deferredIntentValidationFailed(message: errorMessage)
        }
    }

}

// MARK: - Validation helpers

private func == (lhs: STPPaymentIntentSetupFutureUsage, rhs: PaymentSheet.IntentConfiguration.SetupFutureUsage?) -> Bool {
    // Explicitly switch over each case so that the compiler can complain when new cases are added
    switch lhs {
    case .none:
        return rhs == nil
    case .offSession:
        return rhs == .offSession
    case .onSession:
        return rhs == .onSession
    case .unknown:
        return false
    @unknown default:
        return false
    }
}

private func == (lhs: STPSetupIntentUsage, rhs: PaymentSheet.IntentConfiguration.SetupFutureUsage?) -> Bool {
    // Explicitly switch over each case so that the compiler can complain when new cases are added
    switch lhs {
    case .none:
        return rhs == nil
    case .offSession:
        return rhs == .offSession
    case .onSession:
        return rhs == .onSession
    case .unknown:
        return false
    @unknown default:
        return false
    }
}

private func == (lhs: STPPaymentIntentCaptureMethod, rhs: PaymentSheet.IntentConfiguration.CaptureMethod) -> Bool {
    // Explicitly switch over each case so that the compiler can complain when new cases are added
    switch lhs {
    case .automatic:
        return rhs == .automatic
    case .manual:
        return rhs == .manual
    case .unknown:
        return false
    case .automaticAsync:
        return rhs == .automaticAsync
    @unknown default:
        return false
    }
}
