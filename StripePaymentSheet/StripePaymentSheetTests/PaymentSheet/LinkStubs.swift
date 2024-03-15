//
//  LinkStubs.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

struct LinkStubs {
    private init() {}
}

extension LinkStubs {

    struct PaymentMethodIndices {
        static let card = 0
        static let cardWithFailingChecks = 1
        static let bankAccount = 2
        static let expiredCard = 3
        static let notExisting = -1
    }

    static func paymentMethods() -> [ConsumerPaymentDetails] {
        return [
            ConsumerPaymentDetails(
                stripeID: "1"
            ),
            ConsumerPaymentDetails(
                stripeID: "2"
            ),
            ConsumerPaymentDetails(
                stripeID: "3"
            ),
            ConsumerPaymentDetails(
                stripeID: "4"
            ),
        ]
    }

    static func consumerSession() -> ConsumerSession {
        return ConsumerSession(
            clientSecret: "client_secret",
            emailAddress: "user@example.com",
            verificationSessions: []
        )
    }

}
