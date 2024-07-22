//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPApplePayContextFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
@testable import Stripe
@testable import StripeApplePay
@testable import StripeCoreTestUtils
@testable import StripePayments
@testable import StripePaymentsObjcTestUtils
@testable import StripePaymentsTestUtils

class STPTestApplePayContextDelegate: NSObject, STPApplePayContextDelegate {
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCreatePaymentMethod paymentMethod: StripePayments.STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping StripeApplePay.STPIntentClientSecretCompletionBlock) {
        didCreatePaymentMethodDelegateMethod!(paymentMethod, paymentInformation, completion)
    }

    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCompleteWith status: StripePayments.STPPaymentStatus, error: Error?) {
        didCompleteDelegateMethod!(status, error)
    }

    var didCompleteDelegateMethod: ((_ status: STPPaymentStatus, _ error: Error?) -> Void)?
    var didCreatePaymentMethodDelegateMethod: ((_ paymentMethod: STPPaymentMethod?, _ paymentInformation: PKPayment?, _ completion: @escaping STPIntentClientSecretCompletionBlock) -> Void)?
}

class STPApplePayContextFunctionalTest: STPNetworkStubbingTestCase {
    var apiClient: STPApplePayContextFunctionalTestAPIClient!
    var delegate: STPTestApplePayContextDelegate!
    var context: STPApplePayContext!

    override func setUp() {
        super.setUp()
        delegate = STPTestApplePayContextDelegate()
        let apiClient = STPApplePayContextFunctionalTestAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        apiClient.setupStubs()
        apiClient.applePayContext = context
        self.apiClient = apiClient

        context = STPApplePayContext(paymentRequest: STPFixtures.applePayRequest(), delegate: delegate)
        self.apiClient.applePayContext = context
        context?.apiClient = self.apiClient
        context?.authorizationController = STPTestPKPaymentAuthorizationController()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testCompletesManualConfirmationPaymentIntent() {
        var clientSecret: String?
        // A manual confirmation PI confirmed server-side...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { paymentMethod, paymentInformation, completion in
            XCTAssertNotNil(paymentInformation)
            if let stripeId = paymentMethod?.stripeId {
                STPTestingAPIClient.shared.createPaymentIntent(withParams: [
                    "confirmation_method": "manual",
                    "payment_method": stripeId,
                    "confirm": NSNumber(value: true),
                ]) { _clientSecret, _ in
                    XCTAssertNotNil(_clientSecret)
                    clientSecret = _clientSecret
                    completion(clientSecret, nil)
                }
            }
        }

        // ...used with ApplePayContext
        let context = STPApplePayContext(paymentRequest: STPFixtures.applePayRequest(), delegate: self.delegate)!
        context.apiClient = apiClient
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret!) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == .succeeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesAutomaticConfirmationPaymentIntent() {
        var clientSecret: String?
        // An automatic confirmation PI with the PaymentMethod attached...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { newClientSecret, _ in
                clientSecret = newClientSecret
                completion(newClientSecret, nil)
            }
        }

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret!) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == .succeeded)
                XCTAssertEqual(paymentIntent?.shipping?.name, "Jane Doe")
                XCTAssertEqual(paymentIntent?.shipping?.address?.line1, "510 Townsend St")
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesAutomaticConfirmationPaymentIntentManualCapture() {
        var clientSecret: String?
        // An automatic confirmation PI with the PaymentMethod attached...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            STPTestingAPIClient.shared.createPaymentIntent(withParams: ["capture_method": "manual"]) { newClientSecret, _ in
                clientSecret = newClientSecret
                completion(newClientSecret, nil)
            }
        }

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret!) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == .requiresCapture)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesSetupIntent() {
        var clientSecret: String?
        // An automatic confirmation SI...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            STPTestingAPIClient.shared.createSetupIntent(withParams: nil) { newClientSecret, _ in
                clientSecret = newClientSecret
                completion(newClientSecret, nil)
            }
        }

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrieveSetupIntent(withClientSecret: clientSecret!) { setupIntent, setupIntentRetrieveError in
                XCTAssertNil(setupIntentRetrieveError)
                XCTAssert(setupIntent?.status == .succeeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Error tests

    func testBadPaymentIntentClientSecretErrors() {
        var clientSecret: String?
        // An invalid PaymentIntent client secret...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            DispatchQueue.main.async {
                clientSecret = "pi_bad_secret_1234"
                completion(clientSecret, nil)
            }
        }

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .failure)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in an error
            XCTAssertEqual(status, .error)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testBadSetupIntentClientSecretErrors() {
        var clientSecret: String?
        // An invalid SetupIntent client secret...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            DispatchQueue.main.async {
                clientSecret = "seti_bad_secret_1234"
                completion(clientSecret, nil)
            }
        }

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .failure)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in an error
            XCTAssertEqual(status, .error)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Cancel tests

    func testCancelBeforeIntentConfirmsCancels() {
        // Cancelling Apple Pay *before* the context attempts to confirms the PI/SI...
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            self.context.paymentAuthorizationControllerDidFinish(self.context.authorizationController!)  // Simulate cancel before passing PI to the context
            // ...should never retrieve the PI (b/c it is cancelled before)
            completion("A 'client secret' that triggers an exception if fetched", nil)
        }
        // Simulate user tapping 'Pay' button in Apple Pay
        self.context.paymentAuthorizationController(self.context.authorizationController!, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { _ in }

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in a 'user cancel' status
            XCTAssertEqual(status, .userCancellation)
            XCTAssertNil(error)
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCancelAfterPaymentIntentConfirmsStillSucceeds() {
        // Cancelling Apple Pay *after* the context attempts to confirm the PI...
        apiClient?.shouldSimulateCancelAfterConfirmBegins = true

        var clientSecret: String?
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { newClientSecret, _ in
                clientSecret = newClientSecret
                completion(newClientSecret, nil)
            }
        }
        // Simulate user tapping 'Pay' button in Apple Pay
        self.context.paymentAuthorizationController(self.context.authorizationController!, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { _ in }

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret!) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == .succeeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: 20.0, handler: nil) // give this a longer timeout, it tends to take a while
    }

    func testCancelAfterSetupIntentConfirmsStillSucceeds() {
        // Cancelling Apple Pay *after* the context attempts to confirm the SI...
        apiClient?.shouldSimulateCancelAfterConfirmBegins = true

        var clientSecret: String?
        let delegate = self.delegate
        delegate?.didCreatePaymentMethodDelegateMethod = { _, _, completion in
            STPTestingAPIClient.shared.createSetupIntent(withParams: nil) { newClientSecret, _ in
                clientSecret = newClientSecret
                completion(newClientSecret, nil)
            }
        }
        // Simulate user tapping 'Pay' button in Apple Pay
        self.context.paymentAuthorizationController(self.context.authorizationController!, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { _ in }

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, .success)
            XCTAssertNil(error)

            // ...and results in a successful SI
            apiClient?.retrieveSetupIntent(withClientSecret: clientSecret!) { setupIntent, setupIntentRetrieveError in
                XCTAssertNil(setupIntentRetrieveError)
                XCTAssert(setupIntent?.status == .succeeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: 20.0, handler: nil) // give this a longer timeout, it tends to take a while
    }

    // MARK: - Helper

    /// Simulates user tapping 'Pay' button in Apple Pay sheet
    func _startApplePayForContext(withExpectedStatus expectedStatus: PKPaymentAuthorizationStatus) {
        // When the user taps 'Pay', PKPaymentAuthorizationController calls `didAuthorizePayment:completion:`
        // After you call its completion block, it calls `paymentAuthorizationControllerDidFinish:`
        let didCallAuthorizePaymentCompletion = expectation(description: "ApplePayContext called completion block of paymentAuthorizationController:didAuthorizePayment:completion:")
        if let authorizationController = context?.authorizationController {
            context?.paymentAuthorizationController(authorizationController, didAuthorizePayment: STPFixtures.simulatorApplePayPayment(), handler: { [self] result in
                XCTAssertEqual(expectedStatus, result.status)
                DispatchQueue.main.async(execute: { [self] in
                    if let authorizationController = context?.authorizationController {
                        context?.paymentAuthorizationControllerDidFinish(authorizationController)
                    }
                    didCallAuthorizePaymentCompletion.fulfill()
                })
            })
        }
    }
}

class STPTestPKPaymentAuthorizationController: PKPaymentAuthorizationController {
    // Stub dismissViewControllerAnimated: to just call its completion block
    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}
