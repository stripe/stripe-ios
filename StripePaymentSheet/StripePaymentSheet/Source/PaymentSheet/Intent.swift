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
    // TODO: Extract elementsSession out of this enum - semantically, it is not part of an Intent.
    case paymentIntent(elementsSession: STPElementsSession, paymentIntent: STPPaymentIntent)
    case setupIntent(elementsSession: STPElementsSession, setupIntent: STPSetupIntent)
    case deferredIntent(elementsSession: STPElementsSession, intentConfig: PaymentSheet.IntentConfiguration)

    var elementsSession: STPElementsSession {
        switch self {
        case .paymentIntent(let elementsSession, _):
            return elementsSession
        case .setupIntent(let elementsSession, _):
            return elementsSession
        case .deferredIntent(let elementsSession, _):
            return elementsSession
        }
    }

    var unactivatedPaymentMethodTypes: [STPPaymentMethodType] {
        return elementsSession.unactivatedPaymentMethodTypes
    }

    /// A sorted list of payment method types supported by the Intent and PaymentSheet, ordered from most recommended to least recommended.
    var recommendedPaymentMethodTypes: [STPPaymentMethodType] {
        return elementsSession.orderedPaymentMethodTypes
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
        case .deferredIntent(_, let intentConfig):
            return intentConfig
        default:
            return nil
        }
    }

    var cvcRecollectionEnabled: Bool {
        switch self {
        case .deferredIntent(_, let intentConfig):
            return intentConfig.isCVCRecollectionEnabledCallback()
        case .paymentIntent(_, let paymentIntent):
            return paymentIntent.paymentMethodOptions?.card?.requireCvcRecollection ?? false
        case .setupIntent:
            return false
        }
    }

    var currency: String? {
        switch self {
        case .paymentIntent(_, let pi):
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
        case .paymentIntent(_, let pi):
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

    /// True if this is a PaymentIntent with sfu not equal to none or a SetupIntent
    var isSettingUp: Bool {
        switch self {
        case .paymentIntent(_, let paymentIntent):
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

    var cardBrandChoiceEligible: Bool {
        return elementsSession.cardBrandChoice?.eligible ?? false
    }

    var isApplePayEnabled: Bool {
        return elementsSession.isApplePayEnabled
    }
}
