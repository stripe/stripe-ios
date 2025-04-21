//
//  PaymentSheetDeferredValidator.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
struct PaymentSheetDeferredValidator {
    /// Note: We don't validate amount (for any payment method) because there are use cases where the amount can change slightly between PM collection and confirmation.
    static func validate(paymentIntent: STPPaymentIntent,
                         intentConfiguration: PaymentSheet.IntentConfiguration,
                         paymentMethod: STPPaymentMethod,
                         isFlowController: Bool) throws {
        guard case let .payment(_, currency, setupFutureUsage, _, paymentMethodOptions) = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        guard paymentIntent.currency.uppercased() == currency.uppercased() else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent currency (\(paymentIntent.currency.uppercased())) does not match the PaymentSheet.IntentConfiguration currency (\(currency.uppercased())).")
        }
        guard setupFutureUsage != PaymentSheet.IntentConfiguration.SetupFutureUsage.none else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentSheet.IntentConfiguration setupFutureUsage (\(setupFutureUsage?.rawValue ?? "")) is invalid. You can only set it to `.onSession`, `.offSession`, or leave it `nil`.")
        }
        // Validate that the PaymentIntent and IntentConfiguration SFU values are both nil or both non-nil. Don't validate the particular non-nil values are the same (off_session vs on_session).
        let isPaymentIntentSFUSet = paymentIntent.setupFutureUsage != .none
        let isIntentConfigurationSFUSet = setupFutureUsage != nil
        guard isPaymentIntentSFUSet == isIntentConfigurationSFUSet else {
           throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent setupFutureUsage (\(paymentIntent.setupFutureUsage)) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
        }
        try validatePaymentMethodOptions(paymentIntentPaymentMethodOptions: paymentIntent.paymentMethodOptions?.allResponseFields as? [String: Any], paymentMethodOptions: paymentMethodOptions)
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
        guard case .setup = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
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

    static func validatePaymentMethodOptions(paymentIntentPaymentMethodOptions: [String: Any]?, paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions?) throws {
        // Parse the response into a [String: String] dictionary [paymentMethodType: setupFutureUsage]
        let paymentIntentPMOSFU: [String: String] = {
            var result: [String: String] = [:]
            paymentIntentPaymentMethodOptions?.forEach { paymentMethodType, value in
                let dictionary = value as? [String: Any] ?? [:]
                if let setupFutureUsage = dictionary["setup_future_usage"] as? String {
                    result[paymentMethodType] = setupFutureUsage
                }
            }
            return result
        }()
        // Convert the intent configuration payment method options setup future usage values into a [String: String] dictionary
        let intentConfigurationPMOSFU: [String: String] = {
            var result: [String: String] = [:]
            paymentMethodOptions?.setupFutureUsageValues?.forEach { paymentMethodType, setupFutureUsage in
                result[paymentMethodType.identifier] = setupFutureUsage.rawValue
            }
            return result
        }()
        // Validate that the PaymentIntent and IntentConfiguration PMO SFU values match. Don't validate the particular values are the same (off_session vs on_session) but if none, check that both are none.
        let doesPMOSFUMatch = Set(paymentIntentPMOSFU.keys) == Set(intentConfigurationPMOSFU.keys) && intentConfigurationPMOSFU.allSatisfy { paymentMethodType, setupFutureUsage in
                if setupFutureUsage == "none" {
                    return paymentIntentPMOSFU[paymentMethodType] == "none"
                }
                if paymentIntentPMOSFU[paymentMethodType] == "none" {
                    return setupFutureUsage == "none"
                }
                return paymentIntentPMOSFU[paymentMethodType] != nil
            }
        guard doesPMOSFUMatch else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent paymentMethodOptions setupFutureUsage (\(paymentIntentPMOSFU)) does not match the PaymentSheet.IntentConfiguration paymentMethodOptions setupFutureUsage (\(intentConfigurationPMOSFU)).")
        }
    }

}
