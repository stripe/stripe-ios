//
//  STPPaymentMethodAddress+CheckoutElementsController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/30/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripePayments

extension STPPaymentMethodAddress {
    /// Converts to a `CheckoutElementsController.Address`, used for Checkout tax region calculation.
    ///
    /// Returns `nil` if there's no country, since that's the only field Checkout requires.
    var checkoutAddress: CheckoutElementsController.Address? {
        guard let country = country?.nonEmpty else {
            return nil
        }
        return CheckoutElementsController.Address(
            country: country,
            line1: line1?.nonEmpty,
            line2: line2?.nonEmpty,
            city: city?.nonEmpty,
            state: state?.nonEmpty,
            postalCode: postalCode?.nonEmpty
        )
    }
}
