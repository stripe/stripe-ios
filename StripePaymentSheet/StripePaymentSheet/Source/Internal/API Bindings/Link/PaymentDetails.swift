//
//  PaymentDetails.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit

typealias ConsumerSessionWithPaymentDetails = (session: ConsumerSession, paymentDetails: [ConsumerPaymentDetails])

/**
 PaymentDetails response for Link accounts
 
 For internal SDK use only
 */
final class ConsumerPaymentDetails: Decodable {
    let stripeID: String

    init(stripeID: String) {
        self.stripeID = stripeID
    }

    private enum CodingKeys: String, CodingKey {
        case stripeID = "id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stripeID = try container.decode(String.self, forKey: .stripeID)
    }
}
