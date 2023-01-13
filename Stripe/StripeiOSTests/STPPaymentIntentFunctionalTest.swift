//
//  STPPaymentIntentFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentIntentFunctionalTestSwift: XCTestCase {

    // MARK: - US Bank Account
    func createAndConfirmPaymentIntentWithUSBankAccount(
        paymentMethodOptions: STPConfirmUSBankAccountOptions? = nil,
        completion: @escaping (String?) -> Void
    ) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        var clientSecret: String?
        let createPIExpectation = expectation(description: "Create PaymentIntent")
        STPTestingAPIClient.shared().createPaymentIntent(
            withParams: [
                "payment_method_types": ["us_bank_account"],
                "currency": "usd",
                "amount": 1000,
            ],
            account: nil
        ) { intentClientSecret, error in
            XCTAssertNil(error)
            XCTAssertNotNil(intentClientSecret)
            clientSecret = intentClientSecret
            createPIExpectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        guard let clientSecret = clientSecret else {
            XCTFail("Failed to create PaymentIntent")
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

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        if let paymentMethodOptions = paymentMethodOptions {
            let pmo = STPConfirmPaymentMethodOptions()
            pmo.usBankAccountOptions = paymentMethodOptions
            paymentIntentParams.paymentMethodOptions = pmo
        }

        let confirmPIExpectation = expectation(description: "Confirm PaymentIntent")
        client.confirmPaymentIntent(with: paymentIntentParams, expand: ["payment_method"]) {
            paymentIntent,
            error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentIntent)
            XCTAssertNotNil(paymentIntent?.paymentMethod)
            XCTAssertNotNil(paymentIntent?.paymentMethod?.usBankAccount)
            XCTAssertEqual(paymentIntent?.paymentMethod?.usBankAccount?.last4, "6789")
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent?.nextAction?.type, .verifyWithMicrodeposits)
            if let paymentMethodOptions = paymentMethodOptions {
                XCTAssertEqual(
                    paymentIntent?.paymentMethodOptions?.usBankAccount?.setupFutureUsage,
                    paymentMethodOptions.setupFutureUsage
                )
            }
            confirmPIExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        completion(clientSecret)
    }

    func testConfirmPaymentIntentWithUSBankAccount_verifyWithAmounts() {
        createAndConfirmPaymentIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create PaymentIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifyPaymentIntentWithMicrodeposits(
                clientSecret: clientSecret,
                firstAmount: 32,
                secondAmount: 45
            ) { paymentIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(paymentIntent)
                XCTAssertEqual(paymentIntent?.status, .processing)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testConfirmPaymentIntentWithUSBankAccount_verifyWithDescriptorCode() {
        createAndConfirmPaymentIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create PaymentIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifyPaymentIntentWithMicrodeposits(
                clientSecret: clientSecret,
                descriptorCode: "SM11AA"
            ) { paymentIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(paymentIntent)
                XCTAssertEqual(paymentIntent?.status, .processing)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testConfirmUSBankAccountWithPaymentMethodOptions() {
        createAndConfirmPaymentIntentWithUSBankAccount(
            paymentMethodOptions: STPConfirmUSBankAccountOptions(setupFutureUsage: .offSession)
        ) { clientSecret in
            XCTAssertNotNil(clientSecret)
        }
    }

}
