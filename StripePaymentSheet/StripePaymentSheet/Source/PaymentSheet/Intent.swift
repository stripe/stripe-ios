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

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

// MARK: - Intent

/// An internal type representing either a PaymentIntent, SetupIntent, or a "deferred Intent"
enum Intent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)
    case deferredIntent(intentConfig: PaymentSheet.IntentConfiguration)

    var stripeId: String? {
        switch self {
        case .paymentIntent(let intent): intent.stripeId
        case .setupIntent(let intent): intent.stripeID
        case .deferredIntent: nil
        }
    }

    var isPaymentIntent: Bool {
        switch self {
        case .paymentIntent:
            return true
        case .setupIntent:
            return false
        case .deferredIntent(let intentConfig):
            switch intentConfig.mode {
            case .payment:
                return true
            case .setup:
                return false
            }
        }
    }

    var isDeferredIntent: Bool {
        switch self {
        case .paymentIntent:
            return false
        case .setupIntent:
            return false
        case .deferredIntent:
            return true
        }
    }

    var intentConfig: PaymentSheet.IntentConfiguration? {
        switch self {
        case .deferredIntent(let intentConfig):
            return intentConfig
        default:
            return nil
        }
    }

    var cvcRecollectionEnabled: Bool {
        switch self {
        case .deferredIntent(let intentConfig):
            return intentConfig.requireCVCRecollection
        case .paymentIntent(let paymentIntent):
            return paymentIntent.paymentMethodOptions?.card?.requireCvcRecollection ?? false
        case .setupIntent:
            return false
        }
    }

    var currency: String? {
        switch self {
        case .paymentIntent(let pi):
            return pi.currency
        case .setupIntent:
            return nil
        case .deferredIntent(let intentConfig):
            switch intentConfig.mode {
            case .payment(_, let currency, _, _, _):
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
        case .deferredIntent(let intentConfig):
            switch intentConfig.mode {
            case .payment(let amount, _, _, _, _):
                return amount
            case .setup:
                return nil
            }
        }
    }

    var setupFutureUsageString: String? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.setupFutureUsage.stringValue
        case .deferredIntent(let intentConfig):
            if case .payment(_, _, let setupFutureUsage, _, _) = intentConfig.mode {
                return setupFutureUsage?.rawValue
            }
            return nil
        default:
            return nil
        }
    }

    var isPaymentMethodOptionsSetupFutureUsageSet: Bool? {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.paymentMethodOptions?.isSetupFutureUsageSet ?? false
        case .deferredIntent(let intentConfig):
            if case .payment(_, _, _, _, let paymentMethodOptions) = intentConfig.mode {
                guard let setupFutureUsageValues = paymentMethodOptions?.setupFutureUsageValues else {
                    return false
                }
                return !setupFutureUsageValues.isEmpty
            }
            return nil
        default:
            return nil
        }
    }

    /// Whether the intent has setup for future usage set for a payment method type.
    func isSetupFutureUsageSet(for paymentMethodType: STPPaymentMethodType) -> Bool {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.isSetupFutureUsageSet(for: paymentMethodType)
        case .setupIntent:
            return true
        case .deferredIntent(intentConfig: let intentConfig):
            switch intentConfig.mode {
            case .payment(_, _, let setupFutureUsage, _, let paymentMethodOptions):
                // if pmo sfu is non-nil, it overrides the top level sfu
                if let paymentMethodOptionsSetupFutureUsage = paymentMethodOptions?.setupFutureUsageValues?[paymentMethodType] {
                    return paymentMethodOptionsSetupFutureUsage != .none
                }
                return setupFutureUsage != nil
            case .setup:
                return true
            }
        }
    }
}
