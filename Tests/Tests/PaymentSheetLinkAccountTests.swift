//
//  PaymentSheetLinkAccountTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

final class PaymentSheetLinkAccountTests: XCTestCase {

    func testMakePaymentMethodParams() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails)

        XCTAssertEqual(result?.type, .link)
        XCTAssertEqual(result?.link?.paymentDetailsID, "1")
        XCTAssertEqual(result?.link?.credentials as? [String: String], [
            "consumer_session_client_secret": "top_secret"
        ])
        XCTAssertNil(result?.link?.additionalAPIParameters["card"])
    }

    func testMakePaymentMethodParams_withCVC() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub(withCVC: "12345")
        let result = sut.makePaymentMethodParams(from: paymentDetails)

        XCTAssertEqual(result?.link?.additionalAPIParameters["card"] as? [String: String], [
            "cvc": "12345"
        ])
    }

}

extension PaymentSheetLinkAccountTests {

    func makePaymentDetailsStub(withCVC cvc: String? = nil) -> ConsumerPaymentDetails {
        let card = ConsumerPaymentDetails.Details.Card(
            expiryYear: 2030,
            expiryMonth: 1,
            brand: "visa",
            last4: "4242",
            allResponseFields: [:]
        )

        card.cvc = cvc

        return ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: card),
            isDefault: true,
            allResponseFields: [:]
        )
    }

    func makeSUT() -> PaymentSheetLinkAccount {
        return PaymentSheetLinkAccount(
            email: "user@example.com",
            session: ConsumerSession.decodedObject(fromAPIResponse: [
                "consumer_session": [
                    "client_secret": "top_secret",
                    "email_address": "user@example.com",
                    "redacted_phone_number": "+1********55",
                    "support_payment_details_types": ["CARD"]
                ]
            ]),
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            cookieStore: LinkInMemoryCookieStore()
        )
    }

}
