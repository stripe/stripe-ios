//
//  PaymentSheetDeferredValidator.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
enum PaymentSheetDeferredValidator {
    /// Note: We don't validate amount (for any payment method) because there are use cases where the amount can change slightly between PM collection and confirmation.
    static func validate(paymentIntent: STPPaymentIntent,
                         intentConfiguration: PaymentSheet.IntentConfiguration,
                         isFlowController: Bool) throws {
        guard case let .payment(_, currency, _, _, _) = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        guard paymentIntent.currency.uppercased() == currency.uppercased() else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent currency (\(paymentIntent.currency.uppercased())) does not match the PaymentSheet.IntentConfiguration currency (\(currency.uppercased())).")
        }

        /*
         Manual confirmation is only available using FlowController because merchants own the final step of confirmation.
         Showing a successful payment in the complete flow may be misleading when merchants still need to do a final confirmation which could fail e.g., bad network
         */
        if !isFlowController && paymentIntent.confirmationMethod == .manual {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent confirmationMethod (\(paymentIntent.confirmationMethod)) can only be used with PaymentSheet.FlowController.")
        }
    }

    static func validate(intentConfiguration: PaymentSheet.IntentConfiguration) throws {
        guard case .setup = intentConfiguration.mode else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
        }
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

    static func validateSFUAndPMOSFU(
        setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage?,
        paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions?,
        paymentMethodType: STPPaymentMethodType,
        paymentIntent: STPPaymentIntent
    ) throws {
        guard setupFutureUsage != PaymentSheet.IntentConfiguration.SetupFutureUsage.none else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your IntentConfiguration setupFutureUsage (none) is invalid. You can only set it to `.onSession`, `.offSession`, or leave it `nil`.")
        }

        // Parse the PaymentIntent PMO SFU value for the given PM type
        let paymentIntentPMOSFUStringValue: String? = paymentIntent.paymentMethodOptions?.setupFutureUsage(for: paymentMethodType)?.lowercased()

        // Grab the IntentConfiguration PMO SFU values
        let intentConfigurationPMOSFUValues = paymentMethodOptions?.setupFutureUsageValues

        // If you're using PMO SFU on the IntentConfiguration, it's valid if the PaymentIntent doesn't have values set because we'll set them ourselves.
        // See https://docs.google.com/document/d/1AW8j-cJ9ZW5h-LapzXOYrrE2b1XtmVo_SnvbNf-asOU
        if
            let intentConfigurationPMOSFUValues, !intentConfigurationPMOSFUValues.isEmpty,
            paymentIntent.setupFutureUsage == .none && paymentIntentPMOSFUStringValue == nil {
            return
        }
        // If we get here, the PI has SFU or PMO SFU set - validate they match for the given PM type.
        // Don't validate the particular non-nil values are the same (off_session vs on_session).
        // 1. Top-level SFU
        let isPaymentIntentSFUSet = paymentIntent.setupFutureUsage != .none
        let isIntentConfigurationSFUSet = setupFutureUsage != nil
        guard isPaymentIntentSFUSet == isIntentConfigurationSFUSet else {
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent setupFutureUsage (\(paymentIntent.setupFutureUsage)) does not match the IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
        }

        // 2. PMO SFU
        // Note this is a different than top-level SFU b/c PMO SFU has an extra value (.none) to check.
        let intentConfigurationPMOSFUValue = intentConfigurationPMOSFUValues?[paymentMethodType]
        switch (paymentIntentPMOSFUStringValue, intentConfigurationPMOSFUValue) {
        case (nil, nil), ("none", .none?), ("off_session", .offSession), ("on_session", .onSession):
            break
        case ("off_session", .onSession), ("on_session", .offSession):
            // Allow on_session / off_session mismatch
            break
        default:
            throw PaymentSheetError.deferredIntentValidationFailed(message: "Your PaymentIntent payment_method_options[\(paymentMethodType.identifier)][setup_future_usage] value (\(paymentIntentPMOSFUStringValue ?? "nil")) does not match the IntentConfiguration value (\(intentConfigurationPMOSFUValue?.rawValue ?? "nil"))")
        }
    }
}
