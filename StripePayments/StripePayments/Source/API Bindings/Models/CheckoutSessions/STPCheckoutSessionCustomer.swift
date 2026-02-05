//
//  STPCheckoutSessionCustomer.swift
//  StripePayments
//
//  Created by Nick Porter on 2/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Customer data from a CheckoutSession response.
@_spi(STP) public struct STPCheckoutSessionCustomer {
    /// The customer ID.
    public let id: String

    /// Saved payment methods for this customer.
    public let paymentMethods: [STPPaymentMethod]

    /// Customer email address.
    public let email: String?

    /// Customer name.
    public let name: String?

    /// Customer phone number.
    public let phone: String?

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionCustomer? {
        guard let dict = dict,
              let id = dict["id"] as? String else {
            return nil
        }

        // Parse payment methods array
        var paymentMethods: [STPPaymentMethod] = []
        if let pmArray = dict["payment_methods"] as? [[AnyHashable: Any]] {
            for pmDict in pmArray {
                if let pm = STPPaymentMethod.decodedObject(fromAPIResponse: pmDict) {
                    paymentMethods.append(pm)
                }
            }
        }

        return STPCheckoutSessionCustomer(
            id: id,
            paymentMethods: paymentMethods,
            email: dict["email"] as? String,
            name: dict["name"] as? String,
            phone: dict["phone"] as? String
        )
    }
}
