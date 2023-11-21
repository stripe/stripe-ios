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
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is a card PaymentMethod, this contains the user’s card details.
    /// - Note: Only a card's `cvc`, `expMonth`, `expYear`, and `networks.preferred` can be updated.
    @objc public var card: STPPaymentMethodCardParams?

    @objc
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

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: billingDetails)): "billing_details",
            NSStringFromSelector(#selector(getter: card)): "card",
        ]
    }
}
