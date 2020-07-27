//
//  STPPaymentHandlerFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import <OCMock/OCMock.h>
#import <SafariServices/SafariServices.h>

#import "STPTestingAPIClient.h"
#import "STPAPIClient+Beta.h"

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
    [STPAPIClient sharedClient].betas = [NSSet setWithObject:@"alipay_beta=v1"];
}

- (void)testAlipayOpensNativeURLAndCancels {
    
    __block NSString *clientSecret = @"pi_1GiohpFY0qyl6XeWw09oKwWi_secret_Co4Etlq8YhmB6p07LQTP1Yklg";
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);

    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@YES, nil])]).andDo(^(__unused NSInvocation *_) {
        // Simulate the Alipay app opening, followed by the user returning back to the app
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:UIApplicationWillEnterForegroundNotification object:nil]];
        });
    });
    
    // ...should not present anything
    OCMReject([self.presentingViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    
    STPPaymentIntentParams *confirmParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    confirmParams.paymentMethodOptions = [STPConfirmPaymentMethodOptions new];
    confirmParams.paymentMethodOptions.alipayOptions = [STPConfirmAlipayOptions new];
    confirmParams.paymentMethodParams = [STPPaymentMethodParams paramsWithAlipay:[STPPaymentMethodAlipayParams new] billingDetails:nil metadata:nil];
    confirmParams.returnURL = @"foo://bar";
    
    XCTestExpectation *e = [self expectationWithDescription:@""];
    [[STPPaymentHandler sharedHandler] confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * __unused paymentIntent, __unused NSError * _Nullable error) {
        // ...should attempt to open the native URL (ie the alipay app)
        OCMVerify([applicationMock openURL:[OCMArg any]
                                   options:[OCMArg any]
                         completionHandler:[OCMArg isNotNil]]);
        // ...and since we didn't actually authenticate, the final state is canceled
        XCTAssertEqual(status, STPPaymentHandlerActionStatusCanceled);

        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAlipayOpensWebviewAfterNativeURLFails {
    
    __block NSString *clientSecret = @"pi_1GiohpFY0qyl6XeWw09oKwWi_secret_Co4Etlq8YhmB6p07LQTP1Yklg";
    id applicationMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationMock sharedApplication]).andReturn(applicationMock);
    // Simulate the customer not having the Alipay app installed
    OCMStub([applicationMock openURL:[OCMArg any]
                             options:[OCMArg any]
                   completionHandler:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    
    id paymentHandler = OCMPartialMock([STPPaymentHandler sharedHandler]);
    OCMStub([paymentHandler _canPresentWithAuthenticationContext:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    // Simulate the safari VC finishing after presenting it
    OCMStub([self.presentingViewController presentViewController:[OCMArg any] animated:[OCMArg any] completion:[OCMArg any]]).andDo(^(__unused NSInvocation *_) {
        [paymentHandler safariViewControllerDidFinish:self.presentingViewController];
    });
    
    STPPaymentIntentParams *confirmParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    confirmParams.paymentMethodOptions = [STPConfirmPaymentMethodOptions new];
    confirmParams.paymentMethodOptions.alipayOptions = [STPConfirmAlipayOptions new];
    confirmParams.paymentMethodParams = [STPPaymentMethodParams paramsWithAlipay:[STPPaymentMethodAlipayParams new] billingDetails:nil metadata:nil];
    confirmParams.returnURL = @"foo://bar";
    
    XCTestExpectation *e = [self expectationWithDescription:@""];
    [paymentHandler confirmPayment:confirmParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent * __unused paymentIntent, __unused NSError * _Nullable error) {
        // ...should attempt to open the native URL (ie the alipay app)
        OCMVerify([applicationMock openURL:[OCMArg any]
                                   options:[OCMArg any]
                         completionHandler:[OCMArg isNotNil]]);
        // ...and then open UIViewController
        OCMVerify([self.presentingViewController presentViewController:[OCMArg any] animated:[OCMArg any] completion:[OCMArg any]]);

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
