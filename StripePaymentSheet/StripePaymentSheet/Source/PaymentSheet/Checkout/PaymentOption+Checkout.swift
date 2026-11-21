//
//  PaymentOption+CheckoutElementsController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/16/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

extension PaymentOption {
    /// The billing details used to sync a CheckoutSession's billing address for tax calculation.
    ///
    /// This is only read on CheckoutSession confirm paths (see `CheckoutSessionBillingAddressUpdater.syncBillingAddress(from:)`);
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
            return nil
        case .link(let confirmOption):
            // For `.wallet`, the payment details aren't known yet. Native Link updates the tax region while it's open.
            return confirmOption.billingDetails
        }
    }
}
