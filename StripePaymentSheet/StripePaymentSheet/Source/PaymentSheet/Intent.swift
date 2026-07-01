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

/// An internal type representing either a PaymentIntent, SetupIntent, a "deferred Intent", or a Checkout
enum Intent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)
    case deferredIntent(intentConfig: PaymentSheet.IntentConfiguration)
    // TODO(gbirch): Remove Checkout.Session associated value once MPE is MainActor-isolated;
    // we can then access checkout.session directly. This is a temporary stopgap to provide a
    // threadsafe version of the checkout session data.
    case checkout(Checkout, Checkout.Session)

    var stripeId: String? {
        switch self {
        case .paymentIntent(let intent): intent.stripeId
        case .setupIntent(let intent): intent.stripeID
        case .deferredIntent: nil
        case .checkout(_, let session): session.id
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
        case .checkout(_, let session):
            return session.mode == .payment || session.mode == .subscription
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
        case .checkout:
            return false
        }
    }

    var intentConfig: PaymentSheet.IntentConfiguration? {
        switch self {
        case .deferredIntent(let intentConfig):
            return intentConfig
        case .paymentIntent, .setupIntent, .checkout:
            return nil
        }
    }

    var cvcRecollectionEnabled: Bool {
        switch self {
        case .deferredIntent(let intentConfig):
            return intentConfig.requireCVCRecollection
        case .paymentIntent(let paymentIntent):
            return paymentIntent.paymentMethodOptions?.card?.requireCvcRecollection ?? false
        case .setupIntent, .checkout:
            // CheckoutSession does not yet support CVC recollection
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
        case .checkout(_, let session):
            return session.currency
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
        case .checkout(_, let session):
            return session.expectedAmount()
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
        case .checkout(_, let session):
            switch session.mode {
            case .payment:
                return session.setupFutureUsage
            case .setup:
                return nil
            case .subscription, .unknown:
                stpAssertionFailure("subscription and unknown not implemented")
                return nil
            }
        case .setupIntent:
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
        case .checkout(_, let session):
            return session.isPaymentMethodOptionsSetupFutureUsageSet
        case .setupIntent:
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
        case .checkout(_, let session):
            switch session.mode {
            case .payment:
                guard let setupFutureUsage = session.setupFutureUsage(for: paymentMethodType) else {
                    return false
                }
                return setupFutureUsage != "none"
            case .setup:
                return true
            case .subscription, .unknown:
                stpAssertionFailure("subscription and unknown not implemented")
                return false
            }
        }
    }

    func allowsPaymentMethodRemoval(elementsSession: STPElementsSession) -> Bool {
        switch self {
        case .checkout(_, let session):
            return session.customer?.canDetachPaymentMethod ?? false
        case .paymentIntent, .setupIntent, .deferredIntent:
            return elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        }
    }

    func allowsPaymentMethodUpdate(elementsSession: STPElementsSession) -> Bool {
        switch self {
        case .checkout:
            // Checkout sessions always support PM updates
            return true
        case .paymentIntent, .setupIntent, .deferredIntent:
            return elementsSession.paymentMethodUpdateForPaymentSheet
        }
    }
}
