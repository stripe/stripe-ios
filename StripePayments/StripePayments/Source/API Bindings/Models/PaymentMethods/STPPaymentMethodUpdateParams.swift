//
//  STPPaymentMethodUpdateParams.swift
//  StripePayments
//
//  Created by Nick Porter on 11/17/23.
//

import Foundation

/// An object representing parameters used to update a PaymentMethod object.
/// - seealso: https://stripe.com/docs/api/payment_methods/update
public class STPPaymentMethodUpdateParams: NSObject {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is a card PaymentMethod, this contains the user’s card details.
    /// - Note: Only a card's `cvc`, `expMonth`, `expYear`, and `networks.preferred` can be updated.
    public var card: STPPaymentMethodCardParams?

    public convenience init(
        card: STPPaymentMethodCardParams,
        billingDetails: STPPaymentMethodBillingDetails?
    ) {
        self.init()
        self.card = card
        self.billingDetails = billingDetails
    }
}

// MARK: - STPFormEncodable

extension STPPaymentMethodUpdateParams: STPFormEncodable {

    public class func rootObjectName() -> String? {
        return nil
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodUpdateParams.billingDetails: "billing_details",
            \STPPaymentMethodUpdateParams.card: "card",
        ]
    }
}
