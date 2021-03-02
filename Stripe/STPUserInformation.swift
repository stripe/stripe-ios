//
//  STPUserInformation.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// You can use this class to specify information that you've already collected
/// from your user. You can then set the `prefilledInformation` property on
/// `STPPaymentContext`, `STPAddCardViewController`, etc and it will pre-fill
/// this information whenever possible.
public class STPUserInformation: NSObject, NSCopying {
    /// The user's billing address. When set, the add card form will be filled with
    /// this address. The user will also have the option to fill their shipping address
    /// using this address.
    /// @note Set this using `setBillingAddressWithBillingDetails:` to use the billing
    /// details from an `STPPaymentMethod` or `STPPaymentMethodParams` instance.
    @objc public var billingAddress: STPAddress?
    /// The user's shipping address. When set, the shipping address form will be filled
    /// with this address. The user will also have the option to fill their billing
    /// address using this address.
    @objc public var shippingAddress: STPAddress?

    /// A convenience method to populate `billingAddress` with a PaymentMethod's billing details.
    /// @note Calling this overwrites the value of `billingAddress`.
    @objc(setBillingAddressWithBillingDetails:)
    public func setBillingAddress(with billingDetails: STPPaymentMethodBillingDetails) {
        billingAddress = STPAddress(paymentMethodBillingDetails: billingDetails)
    }

    /// :nodoc:
    @objc
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = STPUserInformation()
        copy.billingAddress = billingAddress
        copy.shippingAddress = shippingAddress
        return copy
    }
}
