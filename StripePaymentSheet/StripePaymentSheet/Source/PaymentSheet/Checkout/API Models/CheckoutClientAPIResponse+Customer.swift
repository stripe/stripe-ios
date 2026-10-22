//
//  CheckoutClientAPIResponse+Customer.swift
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

        private enum CodingKeys: String, CodingKey {
            case id, paymentMethods
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            paymentMethods =
                try container.decodeIfPresent([APIResponseDecoded<STPPaymentMethod>].self, forKey: .paymentMethods)?
                .map(\.value) ?? []
        }
    }
}
