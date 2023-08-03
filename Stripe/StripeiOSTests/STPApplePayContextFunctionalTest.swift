//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPApplePayContextFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import StripeApplePay
import StripeCoreTestUtils

class STPTestApplePayContextDelegate: NSObject, STPApplePayContextDelegate {
    var didCompleteDelegateMethod: ((_ status: STPPaymentStatus, _ error: Error?) -> Void)?
    var didCreatePaymentMethodDelegateMethod: ((_ paymentMethod: STPPaymentMethod?, _ paymentInformation: PKPayment?, _ completion: STPIntentClientSecretCompletionBlock) -> Void)?
}

//@implementation STPTestApplePayContextDelegate
//
//- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(STPPaymentStatus)status error:(nullable NSError *)error {
//    self.didCompleteDelegateMethod(status, error);
//}
//
//- (void)applePayContext:(__unused STPApplePayContext *)context didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod paymentInformation:(PKPayment *)paymentInformation completion:(nonnull STPIntentClientSecretCompletionBlock)completion {
//    self.didCreatePaymentMethodDelegateMethod(paymentMethod, paymentInformation, completion);
//}
//
//@end


//@interface STPApplePayContext(Testing) <PKPaymentAuthorizationControllerDelegate>
//@property (nonatomic, nullable) PKPaymentAuthorizationController *authorizationController;
//@end
//
//API_AVAILABLE(ios(13.0))
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
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
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
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
        //            XCTAssertNotNil(_clientSecret);
        //            clientSecret = _clientSecret;
        //            completion(clientSecret, nil);
        //        }];
        //    };

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == STPPaymentIntentStatusSucceeded)
                XCTAssertEqual(paymentIntent?.shipping.name, "Jane Doe")
                XCTAssertEqual(paymentIntent?.shipping.address.line1, "510 Townsend St")
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesAutomaticConfirmationPaymentIntentManualCapture() {
        let clientSecret: String? = nil
        // An automatic confirmation PI with the PaymentMethod attached...
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{@"capture_method": @"manual"} completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
        //            XCTAssertNotNil(_clientSecret);
        //            clientSecret = _clientSecret;
        //            completion(clientSecret, nil);
        //        }];
        //    };

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == STPPaymentIntentStatusRequiresCapture)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCompletesSetupIntent() {
        let clientSecret: String? = nil
        // An automatic confirmation SI...
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
        //            XCTAssertNotNil(_clientSecret);
        //            clientSecret = _clientSecret;
        //            completion(clientSecret, nil);
        //        }];
        //    };

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .success)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrieveSetupIntent(withClientSecret: clientSecret) { setupIntent, setupIntentRetrieveError in
                XCTAssertNil(setupIntentRetrieveError)
                XCTAssert(setupIntent?.status == STPSetupIntentStatusSucceeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Error tests

    func testBadPaymentIntentClientSecretErrors() {
        let clientSecret: String? = nil
        // An invalid PaymentIntent client secret...
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            clientSecret = @"pi_bad_secret_1234";
        //            completion(clientSecret, nil);
        //        });
        //    };

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .failure)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in an error
            XCTAssertEqual(status, STPPaymentStatusError)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testBadSetupIntentClientSecretErrors() {
        let clientSecret: String? = nil
        // An invalid SetupIntent client secret...
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            clientSecret = @"seti_bad_secret_1234";
        //            completion(clientSecret, nil);
        //        });
        //    };

        // ...used with ApplePayContext
        _startApplePayForContext(withExpectedStatus: .failure)

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in an error
            XCTAssertEqual(status, STPPaymentStatusError)
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Cancel tests

    func testCancelBeforeIntentConfirmsCancels() {
        // Cancelling Apple Pay *before* the context attempts to confirms the PI/SI...
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [self.context paymentAuthorizationControllerDidFinish:self.context.authorizationController]; // Simulate cancel before passing PI to the context
        //        // ...should never retrieve the PI (b/c it is cancelled before)
        //        completion(@"A 'client secret' that triggers an exception if fetched", nil);
        //    };

        //    [self.context paymentAuthorizationController:self.context.authorizationController
        //                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
        //                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { status, error in
            // ...and results in a 'user cancel' status
            XCTAssertEqual(status, STPPaymentStatusUserCancellation)
            XCTAssertNil(error)
            didCallCompletion.fulfill()
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCancelAfterPaymentIntentConfirmsStillSucceeds() {
        // Cancelling Apple Pay *after* the context attempts to confirm the PI...
        apiClient?.shouldSimulateCancelAfterConfirmBegins = true

        let clientSecret: String? = nil
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
        //            XCTAssertNotNil(_clientSecret);
        //            clientSecret = _clientSecret;
        //            completion(clientSecret, nil);
        //        }];
        //    };

        //    [self.context paymentAuthorizationController:self.context.authorizationController
        //                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
        //                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay
        //
        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
            XCTAssertNil(error)

            // ...and results in a successful PI
            apiClient?.retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, paymentIntentRetrieveError in
                XCTAssertNil(paymentIntentRetrieveError)
                XCTAssert(paymentIntent?.status == STPPaymentIntentStatusSucceeded)
                didCallCompletion.fulfill()
            }
        }

        waitForExpectations(timeout: 20.0, handler: nil) // give this a longer timeout, it tends to take a while
    }

    func testCancelAfterSetupIntentConfirmsStillSucceeds() {
        // Cancelling Apple Pay *after* the context attempts to confirm the SI...
        apiClient?.shouldSimulateCancelAfterConfirmBegins = true

        let clientSecret: String? = nil
        let delegate = self.delegate
        //    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        //        [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
        //            XCTAssertNotNil(_clientSecret);
        //            clientSecret = _clientSecret;
        //            completion(clientSecret, nil);
        //        }];
        //    };

        //    [self.context paymentAuthorizationController:self.context.authorizationController
        //                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
        //                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay

        // ...calls applePayContext:didCompleteWithStatus:error:
        let didCallCompletion = expectation(description: "applePayContext:didCompleteWithStatus: called")
        delegate?.didCompleteDelegateMethod = { [self] status, error in
            XCTAssertEqual(status, STPPaymentStatusSuccess)
            XCTAssertNil(error)

            // ...and results in a successful SI
            apiClient?.retrieveSetupIntent(withClientSecret: clientSecret) { setupIntent, setupIntentRetrieveError in
                XCTAssertNil(setupIntentRetrieveError)
                XCTAssert(setupIntent?.status == STPSetupIntentStatusSucceeded)
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
