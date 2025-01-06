//
//  PaymentSheetLinkAccountTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

import OHHTTPStubs
import OHHTTPStubsSwift
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

final class PaymentSheetLinkAccountTests: APIStubbedTestCase {

    func testMakePaymentMethodParams() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails, cvc: nil)

        XCTAssertEqual(result?.type, .link)
        XCTAssertEqual(result?.link?.paymentDetailsID, "1")
        XCTAssertEqual(
            result?.link?.credentials as? [String: String],
            [
                "consumer_session_client_secret": "client_secret"
            ]
        )
        XCTAssertNil(result?.link?.additionalAPIParameters["card"])
    }

    func testMakePaymentMethodParams_withCVC() {
        let sut = makeSUT()

        let paymentDetails = makePaymentDetailsStub()
        let result = sut.makePaymentMethodParams(from: paymentDetails, cvc: "1234")

        XCTAssertEqual(
            result?.link?.additionalAPIParameters["card"] as? [String: String],
            [
                "cvc": "1234"
            ]
        )
    }

    func testRefreshesWhenNeeded() {
        let sut = makeSUT()
        let listedPaymentDetailsExp = expectation(description: "Lists payment details")
        let refreshExp = expectation(description: "Refreshes when needed")
        // Set up a stub to return a 401 with the wrong key, otherwise return an empty PM list
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { urlRequest in
            // Check to make sure we've passed the correct secret key
            let body = String(data: urlRequest.httpBodyOrBodyStream!, encoding: .utf8)
            if !body!.contains("unexpired_key") {
                // If it isn't the unexpired key, force a refresh by sending the correct error:
                let errorResponse = [
                    "error":
                        [
                            "message": "Fake invalid consumer session error.",
                            "code": "consumer_session_credentials_invalid",
                            "type": "invalid_request_error",
                        ],
                ]
                return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 401, headers: nil)
            }

            // If we did succeed, send an empty payment details list (which will be treated as a successful response).
            let paymentDetailsEmptyList = ["redacted_payment_details": []]
            return HTTPStubsResponse(jsonObject: paymentDetailsEmptyList, statusCode: 200, headers: nil)
        }

        sut.paymentSheetLinkAccountDelegate = PaymentSheetLinkAccountDelegateStub(expectation: refreshExp)
        // List the payment details. This will fail, refresh the token, then succeed.
        sut.listPaymentDetails { result in
            switch result {
            case .success:
                listedPaymentDetailsExp.fulfill()
            case .failure:
                XCTFail("Should not have failed")
            }
        }
        waitForExpectations(timeout: 5)
    }

}

class PaymentSheetLinkAccountDelegateStub: PaymentSheetLinkAccountDelegate {
    let expectation: XCTestExpectation

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func refreshLinkSession(completion: @escaping (Result<ConsumerSession, Error>) -> Void) {
        // Return a fake session with a "good" key
        let stubSession = ConsumerSession(
            clientSecret: "unexpired_key",
            emailAddress: "user@example.com",
            redactedPhoneNumber: "+1********55",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [.card, .bankAccount]
        )
        completion(.success(stubSession))
        expectation.fulfill()
    }
}

extension PaymentSheetLinkAccountTests {

    func makePaymentDetailsStub() -> ConsumerPaymentDetails {
        return ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: .init(expiryYear: 30, expiryMonth: 10, brand: "visa", last4: "1234", checks: nil)),
            billingAddress: nil,
            billingEmailAddress: nil,
            isDefault: false
        )
    }

    func makeSUT() -> PaymentSheetLinkAccount {
        return PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false
        )
    }

}
