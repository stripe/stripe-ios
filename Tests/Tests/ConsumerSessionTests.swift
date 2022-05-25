//
//  ConsumerSessionTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import Stripe

class ConsumerSessionTests: XCTestCase {

    let apiClient: STPAPIClient = {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return apiClient
    }()

    let cookieStore = LinkInMemoryCookieStore()

    func testLookupSession_noParams() {
        let expectation = self.expectation(description: "loookup consumersession")
        ConsumerSession.lookupSession(for: nil, with: apiClient, cookieStore: cookieStore) { lookupResponse, error in
            XCTAssertNil(error)
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(_, _):
                    XCTFail("Got a response without any params")

                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")

                case .noAvailableLookupParams:
                    break
                }

            } else {
                XCTFail("Received nil ConsumerSession.LookupResponse")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLookupSession_shouldDeleteInvalidSessionCookies() {
        let expectation = self.expectation(description: "Lookup ConsumerSession")

        cookieStore.write(key: cookieStore.sessionCookieKey, value: "bad_session_cookie", allowSync: false)

        ConsumerSession.lookupSession(for: nil, with: apiClient, cookieStore: cookieStore) { lookupResponse, error in
            XCTAssertNil(error, "Unexpected error received")

            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .notFound(_):
                    // Expected response type.
                    break

                case .noAvailableLookupParams, .found(_, _):
                    XCTFail("Unexpected response type: \(lookupResponse.responseType)")
                }
            } else {
                XCTFail("Received nil ConsumerSession.LookupResponse")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
        XCTAssertNil(cookieStore.read(key: cookieStore.sessionCookieKey), "Invalid cookie not deleted")
    }

    func testLookupSession_cookieOnly() {
        _ = createVerifiedConsumerSession()
        let expectation = self.expectation(description: "loookup consumersession")
        ConsumerSession.lookupSession(for: nil, with: apiClient, cookieStore: cookieStore) { lookupResponse, error in
            XCTAssertNil(error)
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(_, _):
                    break

                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")

                case .noAvailableLookupParams:
                    XCTFail("Got no avilable lookup params")
                }

            } else {
                XCTFail("Received nil ConsumerSession.LookupResponse")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLookupSession_existingConsumer() {
        let expectation = self.expectation(description: "loookup consumersession")
        ConsumerSession.lookupSession(
            for: "mobile-payments-sdk-ci+a-consumer@stripe.com",
            with: apiClient,
            cookieStore: cookieStore
        ) { (lookupResponse, error) in
            XCTAssertNil(error)
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(_, _):
                    break

                case .notFound(let errorMessage):
                    XCTFail("Got not found response with \(errorMessage)")

                case .noAvailableLookupParams:
                    XCTFail("Got no avilable lookup params")
                }

            } else {
                XCTFail("Received nil ConsumerSession.LookupResponse")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLookupSession_newConsumer() {
        let expectation = self.expectation(description: "lookup consumersession")
        ConsumerSession.lookupSession(
            for: "mobile-payments-sdk-ci+not-a-consumer@stripe.com",
            with: apiClient,
            cookieStore: cookieStore
        ) { (lookupResponse, error) in
            XCTAssertNil(error)
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(let consumerSession, _):
                    XCTFail("Got unexpected found response with \(consumerSession)")

                case .notFound(_):
                    break

                case .noAvailableLookupParams:
                    XCTFail("Got no avilable lookup params")
                }
            } else {
                XCTFail("Received nil ConsumerSession.LookupResponse")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    // tests signup, createPaymentDetails
    func testSignUpAndCreateDetails() {
        let expectation = self.expectation(description: "consumer sign up")
        let newAccountEmail = "mobile-payments-sdk-ci+\(UUID())@stripe.com"

        var consumerSession: ConsumerSession?
        var consumerPreferences: ConsumerSession.Preferences?

        ConsumerSession.signUp(
            email: newAccountEmail,
            phoneNumber: "+13105551234",
            legalName: nil,
            countryCode: "US",
            with: apiClient,
            cookieStore: cookieStore
        ) { (signupResponse, error) in
            XCTAssertNil(error)

            if let signupResponse = signupResponse {
                XCTAssertTrue(signupResponse.consumerSession.isVerifiedForSignup)
                XCTAssertTrue(signupResponse.consumerSession.verificationSessions.isVerifiedForSignup)
                XCTAssertTrue(
                    signupResponse.consumerSession.verificationSessions.contains(where: { $0.type == .signup })
                )

                consumerSession = signupResponse.consumerSession
                consumerPreferences = signupResponse.preferences
            } else {
                XCTFail("Empty signup response")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)

        if let consumerSession = consumerSession {
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = "4242424242424242"
            cardParams.expMonth = 12
            cardParams.expYear = NSNumber(value: Calendar.autoupdatingCurrent.component(.year, from: Date()) + 1)
            cardParams.cvc = "123"

            let billingParams = STPPaymentMethodBillingDetails()
            billingParams.name = "Payments SDK CI"
            let address = STPPaymentMethodAddress()
            address.postalCode = "55555"
            billingParams.address = address

            let paymentMethodParams = STPPaymentMethodParams.paramsWith(card: cardParams,
                                                                        billingDetails: billingParams,
                                                                        metadata: nil)

            let createExpectation = self.expectation(description: "create payment details")
            consumerSession.createPaymentDetails(
                paymentMethodParams: paymentMethodParams,
                with: apiClient,
                consumerAccountPublishableKey: consumerPreferences?.publishableKey
            ) { (createdPaymentDetails, error) in
                XCTAssertNotNil(createdPaymentDetails)
                XCTAssertNotNil(createdPaymentDetails?.stripeID)
                let details = createdPaymentDetails?.details
                XCTAssertNotNil(details)
                if let details = details {
                    if case .card(let cardDetails) = details {
                        XCTAssertEqual(cardDetails.expiryMonth,  cardParams.expMonth?.intValue)
                        XCTAssertEqual(cardDetails.expiryYear, cardParams.expYear?.intValue)
                    } else {
                        XCTAssert(false)
                    }
                }

                XCTAssertNil(error)
                createExpectation.fulfill()
            }

            wait(for: [createExpectation], timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testListPaymentDetails() {
        let (consumerSession, preferences) = createVerifiedConsumerSession()

        let listExpectation = self.expectation(description: "list payment details")

        consumerSession.listPaymentDetails(
            with: apiClient,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { (paymentDetails, error) in
            XCTAssertNil(error)
            let paymentDetails = try! XCTUnwrap(paymentDetails)
            XCTAssertFalse(paymentDetails.isEmpty)
            listExpectation.fulfill()
        }

        wait(for: [listExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testCreateLinkAccountSession() {
        let createLinkAccountSessionExpectation = self.expectation(description: "Create LinkAccountSession")

        let (consumerSession, preferences) = createVerifiedConsumerSession()
        consumerSession.createLinkAccountSession(
            with: apiClient,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { (linkAccountSession, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(linkAccountSession?.clientSecret)
            createLinkAccountSessionExpectation.fulfill()
        }

        wait(for: [createLinkAccountSessionExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testUpdatePaymentDetails() {
        let (consumerSession, preferences) = createVerifiedConsumerSession()

        let listExpectation = self.expectation(description: "list payment details")
        var storedPaymentDetails = [ConsumerPaymentDetails]()
        
        consumerSession.listPaymentDetails(
            with: apiClient,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { (paymentDetails, error) in
            XCTAssertNil(error)
            storedPaymentDetails = try! XCTUnwrap(paymentDetails)
            listExpectation.fulfill()
        }

        wait(for: [listExpectation], timeout: STPTestingNetworkRequestTimeout)
        
        let billingParams = STPPaymentMethodBillingDetails()
        billingParams.name = "Payments SDK CI"
        let address = STPPaymentMethodAddress()
        address.postalCode = "55555"
        billingParams.address = address
        
        let updateExpectation = self.expectation(description: "update payment details")
        let paymentMethodToUpdate = try! XCTUnwrap(storedPaymentDetails.first)
        guard let prefillDetails = paymentMethodToUpdate.prefillDetails else {
            XCTFail("Payment method doesn't have expected prefill details")
            return
        }
        // toggle between expiry years/months
        let expiryMonth = prefillDetails.expiryMonth == 1 ? 2 : 1
        let expiryYear = prefillDetails.expiryYear == 25 ? 26 : 25

        let updateParams = UpdatePaymentDetailsParams(
            isDefault: !paymentMethodToUpdate.isDefault,
            details: .card(
                expiryDate: .init(month: expiryMonth, year: expiryYear),
                billingDetails: billingParams
            )
        )
        
        consumerSession.updatePaymentDetails(
            with: apiClient,
            id: paymentMethodToUpdate.stripeID,
            updateParams: updateParams,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { (paymentDetails, error) in
            
            XCTAssertNil(error)
            let paymentDetails = try! XCTUnwrap(paymentDetails)
            XCTAssertNotEqual(paymentDetails.isDefault, paymentMethodToUpdate.isDefault)
            let prefillDetails = try! XCTUnwrap(paymentDetails.prefillDetails)
            XCTAssertEqual(expiryMonth, prefillDetails.expiryMonth)
            XCTAssertEqual(CardExpiryDate.normalizeYear(expiryYear), prefillDetails.expiryYear)
            updateExpectation.fulfill()
        }
        
        wait(for: [updateExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLogout() {
        let (consumerSession, preferences) = createVerifiedConsumerSession()

        XCTAssertNotNil(cookieStore.formattedSessionCookies())

        let logoutExpectation = self.expectation(description: "Logout")

        consumerSession.logout(
            with: apiClient,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { session, error in
            XCTAssertNil(error)
            XCTAssertNotNil(session)
            XCTAssertNil(self.cookieStore.formattedSessionCookies())
            logoutExpectation.fulfill()
        }

        wait(for: [logoutExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

}

private extension ConsumerSessionTests {

    func lookupExistingConsumer() -> (ConsumerSession, ConsumerSession.Preferences) {
        var consumerSession: ConsumerSession!
        var consumerPreferences: ConsumerSession.Preferences!

        let lookupExpectation = self.expectation(description: "Lookup consumer")

        let email = "mobile-payments-sdk-ci+a-consumer@stripe.com"

        ConsumerSession.lookupSession(
            for: email,
            with: apiClient,
            cookieStore: cookieStore
        ) {  (lookupResponse, error) in
            XCTAssertNil(error, "Received unexpected error")
            let lookupResponse = try! XCTUnwrap(lookupResponse, "Received nil ConsumerSession.LookupResponse")

            switch lookupResponse.responseType {
            case .found(let session, let preferences):
                consumerSession = session
                consumerPreferences = preferences
            case .notFound(let errorMessage):
                XCTFail("Got not found response with \(errorMessage)")
            case .noAvailableLookupParams:
                XCTFail("Got no avilable lookup params")
            }

            lookupExpectation.fulfill()
        }

        wait(for: [lookupExpectation], timeout: STPTestingNetworkRequestTimeout)

        return (consumerSession, consumerPreferences)
    }

    func createVerifiedConsumerSession() -> (ConsumerSession, ConsumerSession.Preferences) {
        var (consumerSession, preferences) = lookupExistingConsumer()

        // Start verification

        let startVerificationExpectation = self.expectation(description: "Start verification")

        consumerSession.startVerification(
            with: apiClient,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { unverifiedSession, error in
            XCTAssertNil(error, "Received unexpected error: \(String(describing: error))")
            consumerSession = try! XCTUnwrap(unverifiedSession)
            startVerificationExpectation.fulfill()
        }

        wait(for: [startVerificationExpectation], timeout: STPTestingNetworkRequestTimeout)

        // Verify via SMS

        let confirmVerificationExpectation = self.expectation(description: "Confirm verification")

        consumerSession.confirmSMSVerification(
            with: "000000",
            with: apiClient,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: preferences.publishableKey
        ) { (verifiedSession, error) in
            XCTAssertNil(error, "Received unexpected error")
            consumerSession = try! XCTUnwrap(verifiedSession)
            confirmVerificationExpectation.fulfill()
        }

        wait(for: [confirmVerificationExpectation], timeout: STPTestingNetworkRequestTimeout)

        return (consumerSession, preferences)
    }

}
