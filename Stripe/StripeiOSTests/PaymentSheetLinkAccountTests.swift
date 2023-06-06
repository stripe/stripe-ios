//
//  PaymentSheetLinkAccountTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

final class PaymentSheetLinkAccountTests: XCTestCase {
    func test() {
        
    }
}

extension PaymentSheetLinkAccountTests {

    func makePaymentDetailsStub(withCVC cvc: String? = nil) -> ConsumerPaymentDetails {
        let card = ConsumerPaymentDetails.Details.Card(
            expiryYear: 2030,
            expiryMonth: 1,
            brand: "visa",
            last4: "4242",
            checks: nil
        )

        card.cvc = cvc

        return ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: card),
            isDefault: true
        )
    }

    func makeSUT() -> PaymentSheetLinkAccount {
        return PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        )
    }

}
