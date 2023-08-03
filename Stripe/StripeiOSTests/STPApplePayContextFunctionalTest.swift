//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPApplePayContextFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import StripeApplePay
import StripeCoreTestUtils

var _clientSecret: String?
var aNSError: String = ""
//_clientSecret
// ...calls applePayContext:didCompleteWithStatus:error:
var didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
var status: STPPaymentStatus!
var aNSError: STPPaymentStatus!
var paymentIntent: STPPaymentIntent?
var aNSError: STPPaymentIntent?
var clientSecret: String?
// An automatic confirmation PI with the PaymentMethod attached...
var delegate = delegate
var paymentMethod: STPPaymentMethod?
var __unused: STPPaymentMethod?

class STPTestApplePayContextDelegate: NSObject, STPApplePayContextDelegate {
    var aDidCompleteDelegateMethod: ((_ status: STPPaymentStatus, _ error: Error?) -> Void)?
    var aDidCreatePaymentMethodDelegateMethod: ((_ paymentMethod: STPPaymentMethod?, _ paymentInformation: PKPayment?, _ completion: STPIntentClientSecretCompletionBlock) -> Void)?

    func applePayContext(_ STPApplePayContext: __unused) {
var STPApplePayContext = STPApplePayContext    }
}

func didCompleteDelegateMethod(_ status: Int, _ error: Int) {
}

func didCreatePaymentMethodDelegateMethod(_ paymentMethod: Int, _ paymentInformation: Int, _ completion: Int) {
}

extension STPApplePayContext: PKPaymentAuthorizationControllerDelegate {
    var authorizationController: PKPaymentAuthorizationController?
}

@available(iOS 13.0, *)
class STPApplePayContextFunctionalTest: XCTestCase {
    var apiClient: STPApplePayContextFunctionalTestAPIClient?
    var delegate: STPTestApplePayContextDelegate?
    var context: STPApplePayContext?

    override func setUp() {
        delegate = STPTestApplePayContextDelegate()
        if #available(iOS 13.0, *) {
            let apiClient = STPApplePayContextFunctionalTestAPIClient(publishableKey: STPTestingDefaultPublishableKey)
            apiClient.setupStubs()
            apiClient.applePayContext = context
            self.apiClient = apiClient
        } else {
            XCTSkip("Unsupported iOS version")
        }

        context = STPApplePayContext(paymentRequest: STPFixtures.applePayRequest(), delegate: delegate)
        self.apiClient.applePayContext = context
        context?.apiClient = self.apiClient
        context?.authorizationController = STPTestPKPaymentAuthorizationController()
    }

    override func tearDown() {
        HTTPStubs.removeAll()
    }

    func testCompletesManualConfirmationPaymentIntent() {
        var clientSecret: String?
        // A manual confirmation PI confirmed server-side...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { paymentMethod, paymentInformation, completion in
            XCTAssertNotNil(paymentInformation)
            if let stripeId = paymentMethod?.stripeId {
                STPTestingAPIClient.shared().createPaymentIntent(withParams: [
                    "confirmation_method": "manual",
                    "payment_method": stripeId,
                    "confirm": NSNumber(value: true)
                ]) { _clientSecret, error in
                    XCTAssertNotNil(_clientSecret)
                    clientSecret = _clientSecret
                    completion(clientSecret, nil)
                }
            }
        }

        // ...used with ApplePayContext
        let context = STPApplePayContext(paymentRequest: STPFixtures.applePayRequest(), delegate: self.delegate)
        context.apiClient = apiClient
        _startApplePayForContext(withExpectedStatus: PKPaymentAuthorizationStatus.success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status.rawValue, STPPaymentStatus.success.rawValue)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == STPPaymentIntentStatusSucceeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesAutomaticConfirmationPaymentIntent() {
        let clientSecret: String? = nil
        // An automatic confirmation PI with the PaymentMethod attached...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = 
        let paymentMethod: STPPaymentMethod? = nil
        let __unused: STPPaymentMethod
    }
}

class STPTestPKPaymentAuthorizationController: PKPaymentAuthorizationController {
    // Stub dismissViewControllerAnimated: to just call its completion block
    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

func XCTAssertNotNil(_ _clientSecret: Int) {
}

// ...used with ApplePayContext
func XCTAssertEqual(_ status: Int, _ STPPaymentStatusSuccess: Int) {
}

func XCTAssertNil(_ error: Int) {
}

func XCTAssertNil(_ paymentIntentRetrieveError: Int) {
}
