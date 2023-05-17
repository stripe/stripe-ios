//
//  PaymentSheetDeferredValidator.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/23.
//

import Foundation
import StripePayments

struct PaymentSheetDeferredValidator {
    static func validate(paymentIntent: STPPaymentIntent, intentConfiguration: PaymentSheet.IntentConfiguration) throws {
        guard case let .payment(amount, currency, setupFutureUsage, captureMethod) = intentConfiguration.mode else {
            throw PaymentSheetError.unknown(debugDescription: "You returned a PaymentIntent client secret but used a PaymentSheet.IntentConfiguration in setup mode.")
        }
        guard paymentIntent.currency.uppercased() == currency.uppercased() else {
            throw PaymentSheetError.unknown(debugDescription: "Your PaymentIntent currency (\(paymentIntent.currency)) does not match the PaymentSheet.IntentConfiguration currency (\(currency)).")
        }
        guard paymentIntent.setupFutureUsage == setupFutureUsage else {
            throw PaymentSheetError.unknown(debugDescription: "Your PaymentIntent setupFutureUsage (\(paymentIntent.setupFutureUsage)) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
        }
        guard paymentIntent.amount == amount else {
            throw PaymentSheetError.unknown(debugDescription: "Your PaymentIntent amount (\(paymentIntent.amount)) does not match the PaymentSheet.IntentConfiguration amount (\(amount)).")
        }
        guard paymentIntent.captureMethod == captureMethod else {
            throw PaymentSheetError.unknown(debugDescription: "Your PaymentIntent captureMethod (\(paymentIntent.captureMethod)) does not match the PaymentSheet.IntentConfiguration amount (\(captureMethod)).")
        }
    }

    static func validate(setupIntent: STPSetupIntent, intentConfiguration: PaymentSheet.IntentConfiguration) throws {
        guard case let .setup(_, setupFutureUsage) = intentConfiguration.mode else {
            throw PaymentSheetError.unknown(debugDescription: "You returned a SetupIntent client secret but used a PaymentSheet.IntentConfiguration in payment mode.")
        }
        guard setupIntent.usage == setupFutureUsage else {
            throw PaymentSheetError.unknown(debugDescription: "Your SetupIntent usage (\(setupIntent.usage)) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (\(String(describing: setupFutureUsage))).")
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
    @unknown default:
        return false
    }
}
