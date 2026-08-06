//
//  PaymentOption+Checkout.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/16/26.
//

import Foundation
@_spi(STP) import StripePayments

extension PaymentOption {
    /// The billing details used to sync a CheckoutSession's billing address for tax calculation.
    ///
    /// This is only read on CheckoutSession confirm paths (see `Checkout.syncBillingAddress(from:)`);
    /// other flows never consume it.
    var checkoutBillingDetails: STPPaymentMethodBillingDetails? {
        switch self {
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.billingDetails
        case .saved(let paymentMethod, let confirmParams):
            // Saved payment methods have nil confirmParams, so fall back to the payment method's
            // own billing details. Otherwise the billing address is dropped and tax is miscalculated.
            return confirmParams?.paymentMethodParams.billingDetails ?? paymentMethod.billingDetails
        case .external(_, let billingDetails):
            return billingDetails
        case .applePay:
            // TODO(porter) Get Apple Pay working with automatic tax
            return nil
        case .link:
            // Link does not support automatic tax with billing address as source
            return nil
        }
    }
}
