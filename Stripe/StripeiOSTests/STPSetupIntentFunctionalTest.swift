//
//  STPSetupIntentFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPSetupIntentFunctionalTestSwift: STPNetworkStubbingTestCase {

    // MARK: - US Bank Account
    func createAndConfirmSetupIntentWithUSBankAccount(completion: @escaping (String?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        var clientSecret: String?
        let createSIExpectation = expectation(description: "Create SetupIntent")
        STPTestingAPIClient.shared.createSetupIntent(
            withParams: ["payment_method_types": ["us_bank_account"]],
            account: nil
        ) { intentClientSecret, error in
            XCTAssertNil(error)
            XCTAssertNotNil(intentClientSecret)
            clientSecret = intentClientSecret
            createSIExpectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        guard let clientSecret = clientSecret else {
            XCTFail("Failed to create SetupIntent")
            return
        }

        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        usBankAccountParams.accountHolderType = .individual
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"

        let paymentMethodParams = STPPaymentMethodParams(
            usBankAccount: usBankAccountParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret)
        setupIntentParams.paymentMethodParams = paymentMethodParams

        let confirmSIExpectation = expectation(description: "Confirm SetupIntent")
        client.confirmSetupIntent(with: setupIntentParams, expand: ["payment_method"]) {
            setupIntent,
            error in
            XCTAssertNil(error)
            guard let setupIntent else { XCTFail(); return }
            XCTAssertNotNil(setupIntent.paymentMethod)
            XCTAssertNotNil(setupIntent.paymentMethod?.usBankAccount)
            XCTAssertEqual(setupIntent.paymentMethod?.usBankAccount?.last4, "6789")
            XCTAssertEqual(setupIntent.status, .requiresAction)
            XCTAssertEqual(setupIntent.nextAction?.type, .verifyWithMicrodeposits)
            confirmSIExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        completion(clientSecret)
    }

    func testConfirmSetupIntentWithUSBankAccount_verifyWithAmounts() {
        createAndConfirmSetupIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create SetupIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifySetupIntentWithMicrodeposits(
                clientSecret: clientSecret,
                firstAmount: 32,
                secondAmount: 45
            ) { setupIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent?.status, .succeeded)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testConfirmSetupIntentWithUSBankAccount_verifyWithDescriptorCode() {
        createAndConfirmSetupIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create SetupIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifySetupIntentWithMicrodeposits(
                clientSecret: clientSecret,
                descriptorCode: "SM11AA"
            ) { setupIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent?.status, .succeeded)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }
}

//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
extension STPSetupIntentFunctionalTestSwift {
    func testCreateSetupIntentWithTestingServer() {
        let expectation = self.expectation(description: "SetupIntent create.")
        STPTestingAPIClient.shared.createSetupIntent(
            withParams: nil) { clientSecret, error in
            XCTAssertNotNil(clientSecret)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRetrieveSetupIntentSucceeds() {
        // Tests retrieving a previously created SetupIntent succeeds
        let setupIntentClientSecret = "seti_1GGCuIFY0qyl6XeWVfbQK6b3_secret_GnoX2tzX2JpvxsrcykRSVna2lrYLKew"
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Setup Intent retrieve")

        client.retrieveSetupIntent(
            withClientSecret: setupIntentClientSecret) { setupIntent, error in
                XCTAssertNil(error)
                guard let setupIntent else { XCTFail(); return }
                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent.stripeID, "seti_1GGCuIFY0qyl6XeWVfbQK6b3")
                XCTAssertEqual(setupIntent.clientSecret, setupIntentClientSecret)
                XCTAssertEqual(setupIntent.created, Date(timeIntervalSince1970: 1582673622))
                XCTAssertNil(setupIntent.customerID)
                XCTAssertNil(setupIntent.stripeDescription)
                XCTAssertFalse(setupIntent.livemode)
                XCTAssertNil(setupIntent.nextAction)
                XCTAssertNil(setupIntent.paymentMethodID)
                XCTAssertEqual(setupIntent.paymentMethodTypes, [NSNumber(value: STPPaymentMethodType.card.rawValue)])
                XCTAssertEqual(setupIntent.status, STPSetupIntentStatus.requiresPaymentMethod)
                XCTAssertEqual(setupIntent.usage, STPSetupIntentUsage.offSession)
                expectation.fulfill()
            }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmSetupIntentSucceeds() {

        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create SetupIntent.")
        STPTestingAPIClient.shared.createSetupIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "SetupIntent confirm")
        let params = STPSetupIntentConfirmParams(clientSecret: clientSecret!)
        params.returnURL = "example-app-scheme://authorized"
        // Confirm using a card requiring 3DS1 authentication (ie requires next steps)
        params.paymentMethodID = "pm_card_authenticationRequired"
        client.confirmSetupIntent(
            with: params) { setupIntent, error in
                XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
                guard let setupIntent else { XCTFail(); return }

                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent.stripeID, STPSetupIntent.id(fromClientSecret: params.clientSecret))
                XCTAssertEqual(setupIntent.clientSecret, clientSecret)
                XCTAssertFalse(setupIntent.livemode)

                XCTAssertEqual(setupIntent.status, STPSetupIntentStatus.requiresAction)
                XCTAssertNotNil(setupIntent.nextAction)
                XCTAssertEqual(setupIntent.nextAction?.type, STPIntentActionType.redirectToURL)
                XCTAssertEqual(setupIntent.nextAction?.redirectToURL?.returnURL, URL(string: "example-app-scheme://authorized"))
                XCTAssertNotNil(setupIntent.paymentMethodID)
                expectation.fulfill()
            }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - AU BECS Debit

    func testConfirmAUBECSDebitSetupIntent() {

        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createSetupIntent(
            withParams: [
                "payment_method_types": ["au_becs_debit"],
            ],
            account: "au") { createdClientSecret, creationError in
                XCTAssertNotNil(createdClientSecret)
                XCTAssertNil(creationError)
                createExpectation.fulfill()
                clientSecret = createdClientSecret
            }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let becsParams = STPPaymentMethodAUBECSDebitParams()
        becsParams.bsbNumber = "000000" // Stripe test bank
        becsParams.accountNumber = "000123456" // test account

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"

        let params = STPPaymentMethodParams(
            aubecsDebit: becsParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])

        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret!)
        setupIntentParams.paymentMethodParams = params

        let client = STPAPIClient(publishableKey: STPTestingAUPublishableKey)
        let expectation = self.expectation(description: "Setup Intent confirm")

        client.confirmSetupIntent(
            with: setupIntentParams) { setupIntent, error in
                XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
                guard let setupIntent else { XCTFail(); return }

                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent.stripeID, STPSetupIntent.id(fromClientSecret: setupIntentParams.clientSecret))
                XCTAssertNotNil(setupIntent.paymentMethodID)
                XCTAssertEqual(setupIntent.status, STPSetupIntentStatus.succeeded)

                expectation.fulfill()
            }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
