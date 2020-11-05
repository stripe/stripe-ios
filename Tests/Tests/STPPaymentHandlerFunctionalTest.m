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

#import "STPTestingAPIClient.h"


@interface STPPaymentHandlerFunctionalTest : XCTestCase <STPAuthenticationContext>
@property (nonatomic) id presentingViewController;
@end

@interface STPPaymentHandler (Test) <SFSafariViewControllerDelegate>
- (BOOL)_canPresentWithAuthenticationContext:(id<STPAuthenticationContext>)authenticationContext error:(NSError **)error;
@end

@implementation STPPaymentHandlerFunctionalTest

- (void)setUp {
    self.presentingViewController = OCMClassMock([UIViewController class]);
    [STPAPIClient sharedClient].publishableKey = STPTestingDefaultPublishableKey;
}

// N.B. Test mode alipay PaymentIntent's never have a native redirect so we can't test that here
- (void)testAlipayOpensWebviewAfterNativeURLUnavailable {
    
    __block NSString *clientSecret = @"pi_1GiohpFY0qyl6XeWw09oKwWi_secret_Co4Etlq8YhmB6p07LQTP1Yklg";
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    // Simulate the customer not having the Alipay app installed
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    
    id paymentHandler = OCMPartialMock(STPPaymentHandler.sharedHandler);
    
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
    [paymentHandler confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * __unused paymentIntent, __unused NSError * _Nullable error) {
        // ...shouldn't attempt to open the native URL (ie the alipay app)
        OCMReject([applicationMock openURL:[OCMArg any]
                                   options:[OCMArg any]
                         completionHandler:[OCMArg isNotNil]]);
        // ...and then open UIViewController
        OCMVerify([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

        // ...and since we didn't actually authenticate, the final state is canceled
        XCTAssertEqual(status, STPPaymentHandlerActionStatusCanceled);
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (UIViewController *)authenticationPresentingViewController {
    return self.presentingViewController;
}

@end
