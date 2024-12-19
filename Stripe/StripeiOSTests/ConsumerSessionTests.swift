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
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class ConsumerSessionTests: STPNetworkStubbingTestCase {

    var apiClient: STPAPIClient!

    override func setUp() {
        strictParamsEnforcement = false
        super.setUp()
        apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }

    func testLookupSession_noParams() {
        let expectation = self.expectation(description: "Lookup ConsumerSession")

        ConsumerSession.lookupSession(for: nil, emailSource: .customerEmail, sessionID: "abc123", with: apiClient, useMobileEndpoints: false) {
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

    func testLookupSession_existingConsumer() {
        let expectation = self.expectation(description: "Lookup ConsumerSession")

        ConsumerSession.lookupSession(
            for: "mobile-payments-sdk-ci+a-consumer@stripe.com",
            emailSource: .customerEmail,
            sessionID: "abc123",
            with: apiClient,
            useMobileEndpoints: false
        ) { result in
            switch result {
            case .success(let lookupResponse):
                switch lookupResponse.responseType {
                case .found:
                    break  // Pass

                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")

                case .noAvailableLookupParams:
                    XCTFail("Got no available lookup params")
                }
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLookupSession_newConsumer() {
        let expectation = self.expectation(description: "Lookup ConsumerSession")

        ConsumerSession.lookupSession(
            for: "mobile-payments-sdk-ci+not-a-consumer+\(UUID())@stripe.com",
            emailSource: .customerEmail,
            sessionID: "abc123",
            with: apiClient,
            useMobileEndpoints: false
        ) { result in
            switch result {
            case .success(let lookupResponse):
                switch lookupResponse.responseType {
                case .found(let consumerSession):
                    XCTFail("Got unexpected found response with \(consumerSession)")

                case .notFound:
                    break  // Pass

                case .noAvailableLookupParams:
                    XCTFail("Got no available lookup params")
                }
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    // tests signup, createPaymentDetails
    func testSignUpAndCreateDetailsAndLogout() {
        let expectation = self.expectation(description: "consumer sign up")
        let newAccountEmail = "mobile-payments-sdk-ci+\(UUID())@stripe.com"

        var sessionWithKey: ConsumerSession.SessionWithPublishableKey?

        ConsumerSession.signUp(
            email: newAccountEmail,
            phoneNumber: "+13105551234",
            legalName: nil,
            countryCode: "US",
            consentAction: PaymentSheetLinkAccount.ConsentAction.checkbox_v0.rawValue,
            useMobileEndpoints: false,
            with: apiClient
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

        let consumerSession = sessionWithKey!.consumerSession
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

        let createExpectation = self.expectation(description: "create payment details")
        let logoutExpectation = self.expectation(description: "logout")
        let useDetailsAfterLogoutExpectation = self.expectation(description: "try using payment details after logout")
        consumerSession.createPaymentDetails(
            paymentMethodParams: paymentMethodParams,
            with: apiClient,
            consumerAccountPublishableKey: sessionWithKey?.publishableKey
        ) { result in
            switch result {
            case .success:
                // If this succeeds, log out...
                consumerSession.logout(with: self.apiClient, consumerAccountPublishableKey: sessionWithKey?.publishableKey) { logoutResult in
                    switch logoutResult {
                    case .success:
                        // Try to use the session again, it shouldn't work
                        consumerSession.createPaymentDetails(paymentMethodParams: paymentMethodParams, with: self.apiClient, consumerAccountPublishableKey: sessionWithKey?.publishableKey) { loggedOutAuthenticatedActionResult in
                            switch loggedOutAuthenticatedActionResult {
                            case .success:
                                XCTFail("Logout failed to invalidate token")
                            case .failure(let error):

                                guard let stripeError = error as? StripeError,
                                      case let .apiError(stripeAPIError) = stripeError else {
                                    XCTFail("Received unexpected error response")
                                    return
                                }
                                XCTAssertEqual(stripeAPIError.code, "consumer_session_credentials_invalid")
                            }
                            useDetailsAfterLogoutExpectation.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("Logout failed: \(error.nonGenericDescription)")
                    }
                    logoutExpectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            createExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

    // tests signup, createPaymentDetails, Connect Account
    func testSignUpAndCreateDetailsConnectAccount() {
        let expectation = self.expectation(description: "consumer sign up")
        let newAccountEmail = "mobile-payments-sdk-ci+\(UUID())@stripe.com"
        apiClient.stripeAccount = "acct_1QPtbqFZrlYv4BIL"

        var sessionWithKey: ConsumerSession.SessionWithPublishableKey?

        ConsumerSession.signUp(
            email: newAccountEmail,
            phoneNumber: "+13105551234",
            legalName: nil,
            countryCode: "US",
            consentAction: PaymentSheetLinkAccount.ConsentAction.checkbox_v0.rawValue,
            useMobileEndpoints: false,
            with: apiClient
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

        let consumerSession = sessionWithKey!.consumerSession
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

        let createExpectation = self.expectation(description: "create payment details")
        consumerSession.createPaymentDetails(
            paymentMethodParams: paymentMethodParams,
            with: apiClient,
            consumerAccountPublishableKey: sessionWithKey?.publishableKey
        ) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Received error: \(error.nonGenericDescription)")
            }

            createExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
}
