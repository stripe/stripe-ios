//
//  STPCheckoutSessionCustomer.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

/// Customer data from a CheckoutSession response.
struct STPCheckoutSessionCustomer {
    /// The customer ID.
    let id: String

    /// Saved payment methods for this customer.
    let paymentMethods: [STPPaymentMethod]

    /// Customer email address.
    let email: String?

    /// Customer name.
    let name: String?

    /// Customer phone number.
    let phone: String?

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionCustomer? {
        guard let dict = dict,
              let id = dict["id"] as? String else {
            return nil
        }

        // Parse payment methods array
        let paymentMethods: [STPPaymentMethod] = (dict["payment_methods"] as? [[AnyHashable: Any]])?
            .compactMap { STPPaymentMethod.decodedObject(fromAPIResponse: $0) } ?? []

        return STPCheckoutSessionCustomer(
            id: id,
            paymentMethods: paymentMethods,
            email: dict["email"] as? String,
            name: dict["name"] as? String,
            phone: dict["phone"] as? String
        )
    }
}
