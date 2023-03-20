//
//  STPSetupIntentFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@_spi(STP) import StripeCore
@testable import Stripe

class STPSetupIntentFunctionalTestSwift: XCTestCase {

    // MARK: - US Bank Account
    func createAndConfirmSetupIntentWithUSBankAccount(completion: @escaping (String?)->Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        var clientSecret: String? = nil
        let createSIExpectation = expectation(description: "Create SetupIntent")
        STPTestingAPIClient.shared().createSetupIntent(withParams: ["payment_method_types": ["us_bank_account"]],
                                                         account: nil) { intentClientSecret, error in
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
        
        let paymentMethodParams = STPPaymentMethodParams(usBankAccount: usBankAccountParams,
                                                         billingDetails: billingDetails,
                                                         metadata: nil)
        
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret)
        setupIntentParams.paymentMethodParams = paymentMethodParams

        let confirmSIExpectation = expectation(description: "Confirm SetupIntent")
        client.confirmSetupIntent(with: setupIntentParams, expand: ["payment_method"]) { setupIntent, error in
            XCTAssertNil(error)
            XCTAssertNotNil(setupIntent)
            XCTAssertNotNil(setupIntent?.paymentMethod)
            XCTAssertNotNil(setupIntent?.paymentMethod?.usBankAccount)
            XCTAssertEqual(setupIntent?.paymentMethod?.usBankAccount?.last4, "6789")
            XCTAssertEqual(setupIntent?.status, .requiresAction)
            XCTAssertEqual(setupIntent?.nextAction?.type, .verifyWithMicrodeposits)
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
            client.verifySetupIntentWithMicrodeposits(clientSecret: clientSecret,
                                                      firstAmount: 32,
                                                      secondAmount: 45) { setupIntent, error in
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
            client.verifySetupIntentWithMicrodeposits(clientSecret: clientSecret,
                                                      descriptorCode: "SM11AA") { setupIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(setupIntent)
                XCTAssertEqual(setupIntent?.status, .succeeded)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }


}
