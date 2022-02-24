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
                case .found(_):
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

    func testLookupSession_cookieOnly() {
        _ = createVerifiedConsumerSession()
        let expectation = self.expectation(description: "loookup consumersession")
        ConsumerSession.lookupSession(for: nil, with: apiClient, cookieStore: cookieStore) { lookupResponse, error in
            XCTAssertNil(error)
            if let lookupResponse = lookupResponse {
                switch lookupResponse.responseType {
                case .found(_):
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
                case .found(_):
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
                case .found(let consumerSession):
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
        var consumerSession: ConsumerSession? = nil
        ConsumerSession.signUp(email: newAccountEmail,
                               phoneNumber: "+13105551234",
                               countryCode: "US",
                               with: apiClient,
                               cookieStore: cookieStore) { (createdSession, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(createdSession)
            XCTAssertTrue(createdSession?.isVerifiedForSignup ?? false)
            XCTAssertTrue(createdSession?.verificationSessions.isVerifiedForSignup ?? false)
            XCTAssertTrue(createdSession?.verificationSessions.contains(where: { $0.type == .signup }) ?? false)
            consumerSession = createdSession
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
            consumerSession.createPaymentDetails(paymentMethodParams: paymentMethodParams,
                                                 with: apiClient) { (createdPaymentDetails, error) in
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
        let consumerSession = createVerifiedConsumerSession()

        let listExpectation = self.expectation(description: "list payment details")

        consumerSession.listPaymentDetails(with: apiClient) { (paymentDetails, error) in
            XCTAssertNil(error)
            let paymentDetails = try! XCTUnwrap(paymentDetails)
            XCTAssertFalse(paymentDetails.isEmpty)
            listExpectation.fulfill()
        }

        wait(for: [listExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func _testLinkAccountSession(_ shouldAttach: Bool) {
        
        let consumerSession = createVerifiedConsumerSession()
        let linkAccountExpectation = self.expectation(description: "link account session")
        var linkAccountSessionClientSecret: String? = nil
        consumerSession.createLinkAccountSession(with: apiClient,
                                                 successURL: "www.example.com/success",
                                                 cancelURL: "www.example.com/cancel") { (linkAccountSession, error) in
            XCTAssertNil(error)
            linkAccountSessionClientSecret = linkAccountSession?.clientSecret
            XCTAssertNotNil(linkAccountSessionClientSecret)
            linkAccountExpectation.fulfill()
        }
        wait(for: [linkAccountExpectation], timeout: STPTestingNetworkRequestTimeout)
        if shouldAttach,
           let clientSecret = linkAccountSessionClientSecret {
            let attachExpectation = self.expectation(description: "link account session attach")
            
            consumerSession.attachAsAccountHolder(to: clientSecret, with: apiClient) { attachResponse, error in
                XCTAssertNil(error)
                XCTAssertNotNil(attachResponse)
                attachExpectation.fulfill()
            }
            wait(for: [attachExpectation], timeout: STPTestingNetworkRequestTimeout)
        }
    }
            
    func testCreateLinkAccountSession() {
        _testLinkAccountSession(false)
    }
    
    func testCreateAndAttachLinkAccountSession() {
        _testLinkAccountSession(true)
    }
    
    func testUpdatePaymentDetails() {
        let consumerSession = createVerifiedConsumerSession()

        let listExpectation = self.expectation(description: "list payment details")
        var storedPaymentDetails = [ConsumerPaymentDetails]()
        
        consumerSession.listPaymentDetails(with: apiClient) { (paymentDetails, error) in
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
        
        let updateParams = UpdatePaymentDetailsParams(isDefault: !paymentMethodToUpdate.isDefault,
                                                      details: .card(expiryMonth: expiryMonth, expiryYear: expiryYear, billingDetails: billingParams))
        
        consumerSession.updatePaymentDetails(with: apiClient,
                                             id: paymentMethodToUpdate.stripeID,
                                             updateParams: updateParams) { (paymentDetails, error) in
            
            XCTAssertNil(error)
            let paymentDetails = try! XCTUnwrap(paymentDetails)
            XCTAssertNotEqual(paymentDetails.isDefault, paymentMethodToUpdate.isDefault)
            let prefillDetails = try! XCTUnwrap(paymentDetails.prefillDetails)
            XCTAssertEqual(expiryMonth, prefillDetails.expiryMonth)
            XCTAssertEqual(expiryYear, prefillDetails.expiryYear)
            updateExpectation.fulfill()
        }
        
        wait(for: [updateExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLogout() {
        let consumerSession = createVerifiedConsumerSession()

        XCTAssertNotNil(cookieStore.formattedSessionCookies())

        let logoutExpectation = self.expectation(description: "Logout")

        consumerSession.logout(with: apiClient, cookieStore: cookieStore) { session, error in
            XCTAssertNil(error)
            XCTAssertNotNil(session)
            XCTAssertNil(self.cookieStore.formattedSessionCookies())
            logoutExpectation.fulfill()
        }

        wait(for: [logoutExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

}

private extension ConsumerSessionTests {

    func lookupExistingConsumer() -> ConsumerSession {
        var consumerSession: ConsumerSession!

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
            case .found(let session):
                consumerSession = session
            case .notFound(let errorMessage):
                XCTFail("Got not found response with \(errorMessage)")
            case .noAvailableLookupParams:
                XCTFail("Got no avilable lookup params")
            }

            lookupExpectation.fulfill()
        }

        wait(for: [lookupExpectation], timeout: STPTestingNetworkRequestTimeout)

        return consumerSession
    }

    func createVerifiedConsumerSession() -> ConsumerSession {
        var consumerSession = lookupExistingConsumer()

        // Start verification

        let startVerificationExpectation = self.expectation(description: "Start verification")

        consumerSession.startVerification(
            with: apiClient,
            cookieStore: cookieStore
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
            cookieStore: cookieStore
        ) { (verifiedSession, error) in
            XCTAssertNil(error, "Received unexpected error")
            consumerSession = try! XCTUnwrap(verifiedSession)
            confirmVerificationExpectation.fulfill()
        }

        wait(for: [confirmVerificationExpectation], timeout: STPTestingNetworkRequestTimeout)

        return consumerSession
    }

}
