//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPAPIClientNetworkBridgeTest.m
//  StripeiOS
//
//  Created by David Estes on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) import StripePayments
import StripePaymentsTestUtils
import XCTest

class StripeAPIBridgeNetworkTest: STPNetworkStubbingTestCase {
    var client: STPAPIClient!

    override func setUp() {
        super.setUp()
        client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }

    // MARK: Bank Account
    func testCreateTokenWithBankAccount() {
        let exp = expectation(description: "Request complete")
        let params = STPBankAccountParams()
        params.accountNumber = "000123456789"
        params.routingNumber = "110000000"
        params.country = "US"

        client?.createToken(withBankAccount: params) { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: PII

    func testCreateTokenWithPII() {
        let exp = expectation(description: "Create token")

        client?.createToken(withPersonalIDNumber: "123456789") { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateTokenWithSSNLast4() {
        let exp = expectation(description: "Create SSN")

        client?.createToken(withSSNLast4: "1234") { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Connect Accounts

    func testCreateConnectAccount() {
        let exp = expectation(description: "Create connect account")
        let companyParams = STPConnectAccountCompanyParams()
        companyParams.name = "Company"
        let params = STPConnectAccountParams(company: companyParams)
        client?.createToken(withConnectAccount: params) { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Upload

    func testUploadFile() {
        let exp = expectation(description: "Upload file")
        let image = UIImage(
            named: "stp_test_upload_image.jpeg",
            in: Bundle(for: StripeAPIBridgeNetworkTest.self),
            compatibleWith: nil)!

        client?.uploadImage(image, purpose: .disputeEvidence) { file, error in
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Credit Cards

    func testCardToken() {
        let exp = expectation(description: "Create card token")
        let params = STPCardParams()
        params.number = "4242424242424242"
        params.expYear = 42
        params.expMonth = 12
        params.cvc = "123"

        client?.createToken(withCard: params) { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCVCUpdate() {
        let exp = expectation(description: "CVC Update")

        client?.createToken(forCVCUpdate: "123") { token, error in
            XCTAssertNotNil(token)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Sources

    func testCreateRetrieveAndPollSource() {
        let exp = expectation(description: "Upload file")
        let expR = expectation(description: "Retrieve source")
        let expP = expectation(description: "Poll source")

        let card = STPCardParams()
        card.number = "4242424242424242"
        card.expYear = 42
        card.expMonth = 12
        card.cvc = "123"

        let params = STPSourceParams.cardParams(withCard: card)

        client.createSource(with: params) { [self] source, error in
            guard let source = source else {
                XCTFail()
                return
            }
            XCTAssertNil(error)
            exp.fulfill()

            client?.retrieveSource(withId: source.stripeID, clientSecret: source.clientSecret!) { source2, error2 in
                XCTAssertNotNil(source2)
                XCTAssertNil(error2)
                expR.fulfill()
            }

            client?.startPollingSource(withId: source.stripeID, clientSecret: source.clientSecret!, timeout: 10) { [self] source2, error2 in
                XCTAssertNotNil(source2)
                XCTAssertNil(error2)
                client?.stopPollingSource(withId: source.stripeID)
                expP.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Payment Intents

    func testRetrievePaymentIntent() {
        let exp = expectation(description: "Fetch")
        let exp2 = expectation(description: "Fetch with expansion")

        let testClient = STPTestingAPIClient.shared()
        testClient.createPaymentIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            client?.retrievePaymentIntent(withClientSecret: clientSecret!) { pi, error2 in
                XCTAssertNotNil(pi)
                XCTAssertNil(error2)
                exp.fulfill()
            }

            client?.retrievePaymentIntent(withClientSecret: clientSecret!, expand: ["metadata"]) { pi, error2 in
                XCTAssertNotNil(pi)
                XCTAssertNil(error2)
                exp2.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmPaymentIntent() {
        let exp = expectation(description: "Confirm")
        let exp2 = expectation(description: "Confirm with expansion")
        let testClient = STPTestingAPIClient.shared()

        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expYear = NSNumber(value: 42)
        card.expMonth = NSNumber(value: 12)
        card.cvc = "123"

        testClient.createPaymentIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            let params = STPPaymentIntentParams(clientSecret: clientSecret!)
            params.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

            client?.confirmPaymentIntent(with: params) { pi, error2 in
                XCTAssertNotNil(pi)
                XCTAssertNil(error2)
                exp.fulfill()
            }
        }

        testClient.createPaymentIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            let params = STPPaymentIntentParams(clientSecret: clientSecret!)
            params.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

            client?.confirmPaymentIntent(with: params) { pi, error2 in
                XCTAssertNotNil(pi)
                XCTAssertNil(error2)
                exp2.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRefreshPaymentIntent() {
        let exp = expectation(description: "Refresh")

        let testClient = STPTestingAPIClient.shared()
        testClient.createPaymentIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            client?.refreshPaymentIntent(withClientSecret: clientSecret!) { pi, error2 in
                XCTAssertNotNil(pi)
                XCTAssertNil(error2)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Setup Intents

    func testRetrieveSetupIntent() {
        let exp = expectation(description: "Fetch")

        let testClient = STPTestingAPIClient.shared()
        testClient.createSetupIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            client?.retrieveSetupIntent(withClientSecret: clientSecret!) { si, error2 in
                XCTAssertNotNil(si)
                XCTAssertNil(error2)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmSetupIntent() {
        let exp = expectation(description: "Confirm")
        let testClient = STPTestingAPIClient.shared()

        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expYear = NSNumber(value: 42)
        card.expMonth = NSNumber(value: 12)
        card.cvc = "123"

        testClient.createSetupIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            let params = STPSetupIntentConfirmParams(clientSecret: clientSecret!)
            params.paymentMethodParams = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

            client?.confirmSetupIntent(with: params) { si, error2 in
                XCTAssertNotNil(si)
                XCTAssertNil(error2)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRefreshSetupIntent() {
        let exp = expectation(description: "Refresh")

        let testClient = STPTestingAPIClient.shared()
        testClient.createSetupIntent(withParams: nil) { [self] clientSecret, error in
            XCTAssertNil(error)

            client?.refreshSetupIntent(withClientSecret: clientSecret!) { si, error2 in
                XCTAssertNotNil(si)
                XCTAssertNil(error2)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Payment Methods

    func testCreatePaymentMethod() {
        let exp = expectation(description: "Create PaymentMethod")

        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expYear = NSNumber(value: 42)
        card.expMonth = NSNumber(value: 12)
        card.cvc = "123"

        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)

        client?.createPaymentMethod(with: params) { pm, error in
            XCTAssertNotNil(pm)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: Radar

    func testCreateRadarSession() {
        let exp = expectation(description: "Create session")

        // Set fake SID/MUID to make this test replicable
        FraudDetectionData.shared.sid = "123"
        FraudDetectionData.shared.muid = "123"
        FraudDetectionData.shared.sidCreationDate = Date()

        client?.createRadarSession { session, error in
            XCTAssertNotNil(session)
            XCTAssertNil(error)
            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: ApplePay

    func testCreateApplePayToken() {
        let exp = expectation(description: "CreateToken")
        let exp2 = expectation(description: "CreateSource")
        let exp3 = expectation(description: "CreatePM")
        let payment = STPFixtures.applePayPayment()
        client?.createToken(with: payment) { token, error in
            // The certificate used to sign our fake Apple Pay test payment is invalid, which makes sense.
            // Expect an error.
            XCTAssertNil(token)
            XCTAssertNotNil(error)
            exp.fulfill()
        }

        client?.createSource(with: payment) { source, error in
            XCTAssertNil(source)
            XCTAssertNotNil(error)
            exp2.fulfill()
        }

        client?.createPaymentMethod(with: payment) { pm, error in
            XCTAssertNil(pm)
            XCTAssertNotNil(error)
            exp3.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testPKPaymentError() {
        let exp = expectation(description: "Upload file")
        let params = STPCardParams()
        params.number = "4242424242424242"
        params.expYear = 20
        params.expMonth = 12
        params.cvc = "123"

        client?.createToken(withCard: params) { token, error in
            XCTAssertNil(token)
            XCTAssertNotNil(error)
            XCTAssertNotNil(STPAPIClient.pkPaymentError(forStripeError: error))

            exp.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}

// These are a little redundant with the existing
// API tests, but it's a good way to test that the
// bridge works correctly.
