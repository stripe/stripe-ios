//
//  LinkStubs.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@testable import Stripe

struct LinkStubs {
    private init() {}
}

extension LinkStubs {

    struct PaymentMethodIndices {
        static let card = 0
        static let cardWithFailingChecks = 1
        static let bankAccount = 2
        static let notExisting = -1
    }

    static func paymentMethods() -> [ConsumerPaymentDetails] {
        return [
            ConsumerPaymentDetails(
                stripeID: "1",
                details: .card(card: .init(
                    expiryYear: 2030,
                    expiryMonth: 1,
                    brand: "visa",
                    last4: "4242",
                    checks: .init(cvcCheck: .pass, allResponseFields: [:]),
                    allResponseFields: [:]
                )),
                isDefault: true,
                allResponseFields: [:]
            ),
            ConsumerPaymentDetails(
                stripeID: "2",
                details: .card(card: .init(
                    expiryYear: 2030,
                    expiryMonth: 1,
                    brand: "mastercard",
                    last4: "4444",
                    checks: .init(cvcCheck: .fail, allResponseFields: [:]),
                    allResponseFields: [:]
                )),
                isDefault: false,
                allResponseFields: [:]
            ),
            ConsumerPaymentDetails(
                stripeID: "3",
                details: .bankAccount(bankAccount: .init(
                    iconCode: "capitalone",
                    name: "Capital One",
                    last4: "4242",
                    allResponseFields: [:])
                ),
                isDefault: false,
                allResponseFields: [:]
            )
        ]
    }

}
