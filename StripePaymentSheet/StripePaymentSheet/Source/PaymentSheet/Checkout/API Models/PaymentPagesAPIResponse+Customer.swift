//
//  PaymentPagesAPIResponse+Customer.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension CheckoutClientAPIResponse {
    /// Customer data from a Checkout Session response.
    struct Customer: Decodable {
        /// The customer ID.
        let id: String

        /// Saved payment methods for this customer.
        let paymentMethods: [STPPaymentMethod]

        /// Whether the customer can detach saved payment methods from the Checkout Session.
        let canDetachPaymentMethod: Bool

        /// Customer email address.
        let email: String?

        /// Customer name.
        let name: String?

        /// Customer phone number.
        let phone: String?

        init(copying customer: Self, email: String?, canDetachPaymentMethod: Bool) {
            id = customer.id
            paymentMethods = customer.paymentMethods
            self.canDetachPaymentMethod = canDetachPaymentMethod
            self.email = email
            name = customer.name
            phone = customer.phone
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case paymentMethods
            case canDetachPaymentMethod
            case email
            case name
            case phone
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            paymentMethods = try container.decodeIfPresent(
                [LegacyDecoded<STPPaymentMethod>].self,
                forKey: .paymentMethods
            )?.map(\.value) ?? []
            canDetachPaymentMethod = try container.decodeIfPresent(
                Bool.self,
                forKey: .canDetachPaymentMethod
            ) ?? false
            email = try container.decodeIfPresent(String.self, forKey: .email)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            phone = try container.decodeIfPresent(String.self, forKey: .phone)
        }
    }
}
