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
    enum PaymentDetailsType: String, Decodable {
        case card = "CARD"
        case bankAccount = "BANK_ACCOUNT"
        case invalid = "PAYMENT_DETAILS_TYPE_INVALID"
    }

    let stripeID: String
    let paymentDetailsType: PaymentDetailsType

    init(stripeID: String, paymentDetailsType: PaymentDetailsType) {
        self.stripeID = stripeID
        self.paymentDetailsType = paymentDetailsType
    }

    private enum CodingKeys: String, CodingKey {
        case stripeID = "id"
        case paymentDetailsType = "type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stripeID = try container.decode(String.self, forKey: .stripeID)
        self.paymentDetailsType = try container.decode(PaymentDetailsType.self, forKey: .paymentDetailsType)
    }
}
