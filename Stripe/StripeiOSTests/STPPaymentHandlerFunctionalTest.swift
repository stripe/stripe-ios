//
//  STPPaymentHandlerFunctionalTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 4/24/23.
//

@testable import Stripe
@_spi(STP) @testable import StripePayments
import XCTest

// You can add tests in here for payment methods that don't require customer actions (i.e. don't open webviews for customer authentication).
// If they require customer action, use STPPaymentHandlerFunctionalTest.m instead
final class STPPaymentHandlerFunctionalSwiftTest: XCTestCase, STPAuthenticationContext {
    // MARK: - STPAuthenticationContext
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }

    // MARK: - PaymentIntent tests

    func test_card_payment_intent_server_side_confirmation() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient().createPaymentIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["card"],
                "currency": "usd",
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forPayment: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    func test_sepa_debit_payment_intent_server_side_confirmation() {
        // SEPA Debit is a good payment method to test here because
        // - it's a "delayed" or "asynchronous" payment method
        // - it doesn't require customer actions (we can't simulate customer actions in XCTestCase)

        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "SEPA Test Customer"
        billingDetails.email = "test@example.com"

        let sepaDebitDetails = STPPaymentMethodSEPADebitParams()
        sepaDebitDetails.iban = "DE89370400440532013000"

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: .init(sepaDebit: sepaDebitDetails, billingDetails: billingDetails, metadata: nil)) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient().createPaymentIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["sepa_debit"],
                "currency": "eur",
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
                "mandate_data": [
                    "customer_acceptance": [
                        "type": "online",
                        "online": [
                            "user_agent": "123",
                            "ip_address": "172.18.117.125",
                        ],
                    ],
                ],
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forPayment: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .processing)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    // MARK: - SetupIntent tests

    func test_card_setup_intent_server_side_confirmation() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient().createSetupIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["card"],
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forSetupIntent: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    func test_sepa_debit_setup_intent_server_side_confirmation() {
        // SEPA Debit is a good payment method to test here because
        // - it's a "delayed" or "asynchronous" payment method
        // - it doesn't require customer actions (we can't simulate customer actions in XCTestCase)

        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "SEPA Test Customer"
        billingDetails.email = "test@example.com"

        let sepaDebitDetails = STPPaymentMethodSEPADebitParams()
        sepaDebitDetails.iban = "DE89370400440532013000"

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: .init(sepaDebit: sepaDebitDetails, billingDetails: billingDetails, metadata: nil)) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail()
                return
            }
            STPTestingAPIClient().createSetupIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["sepa_debit"],
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
                "mandate_data": [
                    "customer_acceptance": [
                        "type": "online",
                        "online": [
                            "user_agent": "123",
                            "ip_address": "172.18.117.125",
                        ],
                    ],
                ],
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail("\(String(describing: error))")
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forSetupIntent: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded) // Note: I think this should be .processing, but testmode disagrees
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }
    
    // TODO: Rewrite these Objective-C tests without using OCMock
    /*
     
     // N.B. Test mode alipay PaymentIntent's never have a native redirect so we can't test that here
     - (void)testAlipayOpensWebviewAfterNativeURLUnavailable {
         __block NSString *clientSecret = @"pi_123_secret_456";

         id apiClient = OCMPartialMock(STPAPIClient.sharedClient);
         STPPaymentIntent *paymentIntent = [STPFixtures paymentIntent];
         OCMStub([apiClient confirmPaymentIntentWithParams:[OCMArg any] expand:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
             void (^handler)(STPPaymentIntent *paymentIntent, __unused NSError * _Nullable error);
             [invocation getArgument:&handler atIndex:4];
             handler(paymentIntent, nil);
         });

         OCMStub([apiClient retrievePaymentIntentWithClientSecret:[OCMArg any] expand:[OCMArg any] completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
             void (^handler)(STPPaymentIntent *paymentIntent, __unused NSError * _Nullable error);
             [invocation getArgument:&handler atIndex:4];
             handler(paymentIntent, nil);
         });

         id paymentHandler = OCMPartialMock(STPPaymentHandler.sharedHandler);
         OCMStub([paymentHandler apiClient]).andReturn(apiClient);
         
         // Simulate the safari VC finishing after presenting it
         OCMStub([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]).andDo(^(__unused NSInvocation *_) {
             [paymentHandler safariViewControllerDidFinish:self.presentingViewController];
         });
         
         STPPaymentIntentParams *confirmParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
         confirmParams.paymentMethodOptions = [STPConfirmPaymentMethodOptions new];
         confirmParams.paymentMethodOptions.alipayOptions = [STPConfirmAlipayOptions new];
         confirmParams.paymentMethodParams = [STPPaymentMethodParams paramsWithAlipay:[STPPaymentMethodAlipayParams new] billingDetails:nil metadata:nil];
         confirmParams.returnURL = @"foo://bar";

         XCTestExpectation *e = [self expectationWithDescription:@""];
         [paymentHandler confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * __unused pi, __unused NSError * _Nullable error) {
             // ...shouldn't attempt to open the native URL (ie the alipay app)
             OCMReject([self.applicationMock openURL:[OCMArg any]
                                        options:[OCMArg any]
                              completionHandler:[OCMArg isNotNil]]);
             // ...and then open UIViewController
             OCMVerify([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

             // ...and since we didn't actually authenticate, the final state is canceled
             XCTAssertEqual(status, STPPaymentHandlerActionStatusCanceled);
             [e fulfill];
         }];
         [self waitForExpectationsWithTimeout:4 handler:nil];
         [paymentHandler stopMocking]; // paymentHandler is a singleton, so we need to manually call `stopMocking`
     }

     - (void)test_oxxo_payment_intent_server_side_confirmation {
         // OXXO is interesting b/c the PI status after handling next actions is requires_action, not succeeded.
         id paymentHandler = OCMPartialMock(STPPaymentHandler.sharedHandler);
         
         // Simulate the safari VC finishing after presenting it
         OCMStub([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]).andDo(^(__unused NSInvocation *_) {
             [paymentHandler safariViewControllerDidFinish:self.presentingViewController];
         });
         
         STPAPIClient *apiClient = [[STPAPIClient alloc] initWithPublishableKey: STPTestingMEXPublishableKey];
         [STPAPIClient sharedClient].publishableKey = STPTestingMEXPublishableKey;
         
         STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
         billingDetails.name = @"Test Customer";
         billingDetails.email = @"test@example.com";
         
         XCTestExpectation *e = [self expectationWithDescription:@""];
         STPPaymentMethodParams *params = [[STPPaymentMethodParams alloc] initWithOxxo:[STPPaymentMethodOXXOParams new] billingDetails:billingDetails metadata:nil];
         [apiClient createPaymentMethodWithParams:params completion:^(STPPaymentMethod * paymentMethod, NSError * error) {
             XCTAssertNil(error);
             NSDictionary *pi_params = @{
                 @"confirm": @"true",
                 @"payment_method_types": @[@"oxxo"],
                 @"currency": @"mxn",
                 @"amount": @1099,
                 @"payment_method": paymentMethod.stripeId,
                 @"return_url": @"foo://z"
             };
             [[STPTestingAPIClient new] createPaymentIntentWithParams:pi_params account:@"mex" apiVersion:nil completion:^(NSString * clientSecret, NSError * error2) {
                 XCTAssertNil(error2);
                 [paymentHandler handleNextActionForPayment:clientSecret withAuthenticationContext:self returnURL:@"foo://z" completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * paymentIntent, NSError * error3) {
                     XCTAssertNil(error3);
                     XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
                     XCTAssertEqual(status, STPPaymentHandlerActionStatusSucceeded);
                     [e fulfill];
                 }];
             }];
         }];
         [self waitForExpectationsWithTimeout:4 handler:nil];
         [paymentHandler stopMocking]; // paymentHandler is a singleton, so we need to manually call `stopMocking`
     }
     
     */
}
