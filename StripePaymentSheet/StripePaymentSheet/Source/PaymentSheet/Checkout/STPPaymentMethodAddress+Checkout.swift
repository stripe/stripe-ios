//
//  STPPaymentMethodAddress+CheckoutController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/30/26.
//

import Foundation
@_spi(STP) import StripePayments

extension STPPaymentMethodAddress {
    /// Converts to a `CheckoutController.Address`, used for Checkout tax region calculation.
    ///
    /// Returns `nil` if there's no country, since that's the only field Checkout requires.
    var checkoutAddress: CheckoutController.Address? {
        guard let country = country?.nonEmpty else {
            return nil
        }
        return CheckoutController.Address(
            country: country,
            line1: line1?.nonEmpty,
            line2: line2?.nonEmpty,
            city: city?.nonEmpty,
            state: state?.nonEmpty,
            postalCode: postalCode?.nonEmpty
        )
    }
}
