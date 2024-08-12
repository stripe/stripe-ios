//
//  STPPaymentHandlerFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Stripe;
#import <OCMock/OCMock.h>
#import <SafariServices/SafariServices.h>

@import StripePaymentsObjcTestUtils;

@interface STPPaymentHandlerFunctionalTest : XCTestCase <STPAuthenticationContext>
@property (nonatomic) id presentingViewController;
@property (nonatomic) id applicationMock;
@end

@interface STPPaymentHandler (Test) <SFSafariViewControllerDelegate>
- (BOOL)_canPresentWithAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext error:(NSError **)error;
@end

@implementation STPPaymentHandlerFunctionalTest

- (void)setUp {
    self.presentingViewController = OCMClassMock([UIViewController class]);
    // Mock UIApplication.shared, which is otherwise not available in XCTestCase, to always call its completion block with @NO (i.e. it couldn't open a native app with the URL)
    self.applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([self.applicationMock sharedApplication]).andReturn(self.applicationMock);
    OCMStub([self.applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    [STPAPIClient sharedClient].publishableKey = STPTestingDefaultPublishableKey;
}

// N.B. Test mode alipay PaymentIntent's never have a native redirect so we can't test that here
- (void)testAlipayOpensWebviewAfterNativeURLUnavailable {
    __block NSString *clientSecret = @"pi_123_secret_456";

    id apiClient = OCMPartialMock(STPAPIClient.sharedClient);
    NSMutableDictionary *paymentIntentJSON = [[STPTestUtils jsonNamed:@"PaymentIntent"] mutableCopy];
    paymentIntentJSON[@"payment_method"] = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard];
    STPPaymentIntent *paymentIntent = [STPPaymentIntent decodedObjectFromAPIResponse:paymentIntentJSON];
    
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
    [paymentHandler confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * __unused _, __unused NSError * _Nullable error) {
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

- (UIViewController *)authenticationPresentingViewController {
    return self.presentingViewController;
}

@end
