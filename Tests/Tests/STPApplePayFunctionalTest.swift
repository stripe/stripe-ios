//
//  STPApplePayTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/21/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

import PassKit
import XCTest

@testable import Stripe
@testable import StripeApplePay

class STPApplePayFunctionalTest: STPNetworkStubbingTestCase {
    override func setUp() {
        //        self.recordingMode = YES;
        super.setUp()
    }

    // TODO: regenerate these fixtures with a fresh/real PKPayment
    func testCreateTokenWithPaymentClassic() {
        let payment = STPFixtures.applePayPayment()
        let client = STPAPIClient(publishableKey: "pk_test_vOo1umqsYxSrP5UXfOeL3ecm")

        let expectation = self.expectation(description: "Apple pay token creation")
        client.createToken(
            with: payment
        ) { token, error in
            expectation.fulfill()
            XCTAssertNil(token, "token should be nil")
            guard let error = error else {
                XCTFail("error should not be nil")
                return
            }

            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
            // can be decrypted by the backend.
            XCTAssert(
                ((error as NSError).userInfo[STPError.errorMessageKey] as? NSString)?.range(
                    of: "too long"
                ).location != NSNotFound,
                "Error is unrelated to 24-hour expiry: \(error)")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testCreateTokenWithPayment() {
        let payment = STPFixtures.applePayPayment()
        let client = STPAPIClient(publishableKey: "pk_test_vOo1umqsYxSrP5UXfOeL3ecm")

        let expectation = self.expectation(description: "Apple pay token creation")
        StripeAPI.Token.create(
            apiClient: client,
            payment: payment
        ) { result in
            expectation.fulfill()
            XCTAssertNil(try? result.get(), "token should be nil")
            guard case .failure(let error) = result else {
                XCTFail("error should not be nil")
                return
            }

            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
            // can be decrypted by the backend.
            XCTAssert(
                ((error as NSError).userInfo[STPError.errorMessageKey] as? NSString)?.range(
                    of: "too long"
                ).location != NSNotFound,
                "Error is unrelated to 24-hour expiry: \(error)")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testCreateSourceWithPayment() {
        let payment = STPFixtures.applePayPayment()
        let client = STPAPIClient(publishableKey: "pk_test_vOo1umqsYxSrP5UXfOeL3ecm")

        let expectation = self.expectation(description: "Apple pay source creation")
        client.createSource(
            with: payment
        ) { source, error in
            expectation.fulfill()
            XCTAssertNil(source, "token should be nil")
            guard let error = error else {
                XCTFail("error should not be nil")
                return
            }

            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
            // can be decrypted by the backend.
            XCTAssert(
                ((error as NSError).userInfo[STPError.errorMessageKey] as? NSString)?.range(
                    of: "too long"
                ).location != NSNotFound,
                "Error is unrelated to 24-hour expiry: \(error)")
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
