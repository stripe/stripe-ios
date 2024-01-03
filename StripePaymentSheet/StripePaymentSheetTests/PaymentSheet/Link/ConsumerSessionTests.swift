//
//  ConsumerSessionTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class ConsumerSessionTests: XCTestCase {

    let apiClient: STPAPIClient = {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return apiClient
    }()

    let cookieStore = LinkInMemoryCookieStore()

    func testLookupSession_noParams() {
        let expectation = self.expectation(description: "Lookup ConsumerSession")

        ConsumerSession.lookupSession(for: nil, with: apiClient, cookieStore: cookieStore) {
            result in
            switch result {
            case .success(let lookupResponse):
                switch lookupResponse.responseType {
                case .found:
                    XCTFail("Got a response without any params")

                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")

                case .noAvailableLookupParams:
                    break  // Pass
                }
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    // tests signup, createPaymentDetails
    func testSignUpAndCreateDetailsAndRefreshToken() {
        let expectation = self.expectation(description: "consumer sign up")
        let newAccountEmail = "mobile-payments-sdk-ci+\(UUID())@stripe.com"

        var sessionWithKey: ConsumerSession.SessionWithPublishableKey?

        ConsumerSession.signUp(
            email: newAccountEmail,
            phoneNumber: "+13105551234",
            legalName: nil,
            countryCode: "US",
            consentAction: nil,
            with: apiClient,
            cookieStore: cookieStore
        ) { result in
            switch result {
            case .success(let signupResponse):
                XCTAssertTrue(signupResponse.consumerSession.isVerifiedForSignup)
                XCTAssertTrue(
                    signupResponse.consumerSession.verificationSessions.isVerifiedForSignup
                )
                XCTAssertTrue(
                    signupResponse.consumerSession.verificationSessions.contains(where: {
                        $0.type == .signup
                    })
                )

                sessionWithKey = signupResponse
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)

        if let consumerSession = sessionWithKey?.consumerSession {
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = "4242424242424242"
            cardParams.expMonth = 12
            cardParams.expYear = NSNumber(
                value: Calendar.autoupdatingCurrent.component(.year, from: Date()) + 1
            )
            cardParams.cvc = "123"

            let billingParams = STPPaymentMethodBillingDetails()
            billingParams.name = "Payments SDK CI"
            let address = STPPaymentMethodAddress()
            address.postalCode = "55555"
            address.country = "US"
            billingParams.address = address

            let paymentMethodParams = STPPaymentMethodParams.paramsWith(
                card: cardParams,
                billingDetails: billingParams,
                metadata: nil
            )

            let verifyCardDetailsExpectation = self.expectation(description: "verify card details for accelerator")
            let createExpectation = self.expectation(description: "create payment details")
            consumerSession.createPaymentDetails(
                paymentMethodParams: paymentMethodParams,
                with: apiClient,
                consumerAccountPublishableKey: sessionWithKey?.publishableKey,
                saveAsActive: true // Save as active details so the verify call succeeds
            ) { result in
                switch result {
                case .success(let createdPaymentDetails):
                    if case .card(let cardDetails) = createdPaymentDetails.details {
                        XCTAssertEqual(cardDetails.expiryMonth, cardParams.expMonth?.intValue)
                        XCTAssertEqual(cardDetails.expiryYear, cardParams.expYear?.intValue)

                        consumerSession.verifyDefaultPaymentDetails(consumerAccountPublishableKey: sessionWithKey?.publishableKey, last4: "4242") { result in
                            switch result {
                            case .success(let verifyDetails):
                                XCTAssert(verifyDetails.isDefault)
                            case .failure(let error):
                                XCTFail("Received error: \(error.nonGenericDescription)")
                            }

                            verifyCardDetailsExpectation.fulfill()
                        }

                    } else {
                        XCTAssert(false)
                    }
                case .failure(let error):
                    XCTFail("Received error: \(error.nonGenericDescription)")
                }

                createExpectation.fulfill()
            }

            wait(for: [createExpectation, verifyCardDetailsExpectation], timeout: STPTestingNetworkRequestTimeout)
        }
    }

}

extension ConsumerSessionTests {
    fileprivate func lookupExistingConsumer() -> ConsumerSession.SessionWithPublishableKey {
        var sessionWithKey: ConsumerSession.SessionWithPublishableKey!

        let lookupExpectation = self.expectation(description: "Lookup ConsumerSession")

        let email = "mobile-payments-sdk-ci+a-consumer@stripe.com"

        ConsumerSession.lookupSession(
            for: email,
            with: apiClient,
            cookieStore: cookieStore
        ) { result in
            switch result {
            case .success(let lookupResponse):
                switch lookupResponse.responseType {
                case .found(let session):
                    sessionWithKey = session
                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")
                case .noAvailableLookupParams:
                    XCTFail("Got no avilable lookup params")
                }
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            lookupExpectation.fulfill()
        }

        wait(for: [lookupExpectation], timeout: STPTestingNetworkRequestTimeout)

        return sessionWithKey
    }
}
