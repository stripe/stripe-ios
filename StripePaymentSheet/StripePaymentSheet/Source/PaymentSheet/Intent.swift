//
//  Intent.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
//  This file contains types that abstract over PaymentIntent and SetupIntent for convenience.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

// MARK: - Intent

/// An internal type representing either a PaymentIntent, SetupIntent, or a "deferred Intent"
enum Intent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)
    case deferredIntent(elementsSession: STPElementsSession, intentConfig: PaymentSheet.IntentConfiguration)

    var unactivatedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.unactivatedPaymentMethodTypes
        case .setupIntent(let si):
            return si.unactivatedPaymentMethodTypes
        case .deferredIntent(let elementsSession, _):
            return elementsSession.unactivatedPaymentMethodTypes
        }
    }

    /// A sorted list of payment method types supported by the Intent and PaymentSheet, ordered from most recommended to least recommended.
    var recommendedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.orderedPaymentMethodTypes
        case .setupIntent(let si):
            return si.orderedPaymentMethodTypes
        case .deferredIntent(let elementsSession, _):
            return elementsSession.orderedPaymentMethodTypes
        }
    }

    var isPaymentIntent: Bool {
        switch self {
        case .paymentIntent:
            return true
        case .setupIntent:
            return false
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment:
                return true
            case .setup:
                return false
            }
        }
    }

    var intentConfig: PaymentSheet.IntentConfiguration? {
        switch self {
        case .deferredIntent(_, let intentConfig):
            return intentConfig
        default:
            return nil
        }
    }

    var currency: String? {
        switch self {
        case .paymentIntent(let pi):
            return pi.currency
        case .setupIntent:
            return nil
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(_, let currency, _, _):
                return currency
            case .setup(let currency, _):
                return currency
            }
        }
    }

    var amount: Int? {
        switch self {
        case .paymentIntent(let pi):
            return pi.amount
        case .setupIntent:
            return nil
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(let amount, _, _, _):
                return amount
            case .setup:
                return nil
            }
        }
    }

    /// True if this ia PaymentIntent with sfu not equal to none or a SetupIntent
    var isSettingUp: Bool {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.setupFutureUsage != .none
        case .setupIntent:
            return true
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(_, _, let setupFutureUsage, _):
                return setupFutureUsage != nil
            case .setup:
                return true
            }
        }
    }

    var isInTerminalState: Bool {
        switch self {
        case .paymentIntent(let pi):
            return [.succeeded, .canceled].contains(pi.status)
        case .setupIntent(let si):
            return [.succeeded, .canceled].contains(si.status)
        case .deferredIntent:
            return false
        }
    }
}
