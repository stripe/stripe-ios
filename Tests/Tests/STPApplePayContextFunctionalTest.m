//
//  STPApplePayContextFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

#import "STPApplePayContext.h"
#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"
#import "STPNetworkStubbingTestCase.h"
#import "STPFixtures.h"

@interface STPTestApplePayContextDelegate: NSObject <STPApplePayContextDelegate>
@property (nonatomic) void (^didCompleteDelegateMethod)(STPPaymentStatus status, NSError *error);
@property (nonatomic) void (^didCreatePaymentMethodDelegateMethod)(STPPaymentMethod *paymentMethod, PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion);

@end

@implementation STPTestApplePayContextDelegate

- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(STPPaymentStatus)status error:(nullable NSError *)error {
    self.didCompleteDelegateMethod(status, error);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod paymentInformation:(PKPayment *)paymentInformation completion:(nonnull STPIntentClientSecretCompletionBlock)completion {
    self.didCreatePaymentMethodDelegateMethod(paymentMethod, paymentInformation, completion);
}

@end


@interface STPApplePayContext(Testing) <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic, nullable) PKPaymentAuthorizationViewController *viewController;
@end

@interface STPApplePayContextFunctionalTest : XCTestCase
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPTestApplePayContextDelegate *delegate;
@property (nonatomic) STPApplePayContext *context;

@end

@implementation STPApplePayContextFunctionalTest

- (void)setUp {
    self.delegate = [STPTestApplePayContextDelegate new];
    self.apiClient = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    
    // Stub dismissViewControllerAnimated: to just call its completion block
    XCTestExpectation *didDismissVC = [self expectationWithDescription:@"viewController dismissed"];
    id mockVC = OCMClassMock([PKPaymentAuthorizationViewController class]);
    OCMStub([mockVC dismissViewControllerAnimated:YES completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^dismissCompletion)(void);
        [invocation getArgument:&dismissCompletion atIndex:3];
        dismissCompletion();
        [didDismissVC fulfill];
    });
    self.context = [[STPApplePayContext alloc] initWithPaymentRequest:[STPFixtures applePayRequest] delegate:self.delegate];
    self.context.apiClient = self.apiClient;
    self.context.viewController = mockVC;
}

- (void)testCompletesManualConfirmationPaymentIntent {
    __block NSString *clientSecret;
    // A manual confirmation PI confirmed server-side...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(STPPaymentMethod *paymentMethod, PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        XCTAssertNotNil(paymentInformation);
        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{@"confirmation_method": @"manual", @"payment_method": paymentMethod.stripeId, @"confirm": @YES} completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };
    
    // ...used with ApplePayContext
    STPApplePayContext *context = [[STPApplePayContext alloc] initWithPaymentRequest:[STPFixtures applePayRequest] delegate:self.delegate];
    context.apiClient = self.apiClient;
    [self _startApplePayForContextWithExpectedStatus:PKPaymentAuthorizationStatusSuccess];
    
    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        XCTAssertEqual(status, STPPaymentStatusSuccess);
        XCTAssertNil(error);

        // ...and results in a successful PI
        [self.apiClient retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError *paymentIntentRetrieveError) {
            XCTAssertNil(paymentIntentRetrieveError);
            XCTAssert(paymentIntent.status == STPPaymentIntentStatusSucceeded);
            [didCallCompletion fulfill];
        }];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCompletesAutomaticConfirmationPaymentIntent {
    __block NSString *clientSecret;
    // An automatic confirmation PI with the PaymentMethod attached...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };
    
    // ...used with ApplePayContext
    [self _startApplePayForContextWithExpectedStatus:PKPaymentAuthorizationStatusSuccess];
    
    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        XCTAssertEqual(status, STPPaymentStatusSuccess);
        XCTAssertNil(error);

        // ...and results in a successful PI
        [self.apiClient retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError *paymentIntentRetrieveError) {
            XCTAssertNil(paymentIntentRetrieveError);
            XCTAssert(paymentIntent.status == STPPaymentIntentStatusSucceeded);
            XCTAssertEqualObjects(paymentIntent.shipping.name, @"Jane Doe");
            XCTAssertEqualObjects(paymentIntent.shipping.address.line1, @"510 Townsend St");
            [didCallCompletion fulfill];
        }];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCompletesAutomaticConfirmationPaymentIntentManualCapture {
    __block NSString *clientSecret;
    // An automatic confirmation PI with the PaymentMethod attached...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{@"capture_method": @"manual"} completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };
    
    // ...used with ApplePayContext
    [self _startApplePayForContextWithExpectedStatus:PKPaymentAuthorizationStatusSuccess];
    
    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        XCTAssertEqual(status, STPPaymentStatusSuccess);
        XCTAssertNil(error);

        // ...and results in a successful PI
        [self.apiClient retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * paymentIntentRetrieveError) {
            XCTAssertNil(paymentIntentRetrieveError);
            XCTAssert(paymentIntent.status == STPPaymentIntentStatusRequiresCapture);
            [didCallCompletion fulfill];
        }];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testBadPaymentIntentClientSecretErrors {
    __block NSString *clientSecret;
    // An invalid PaymentIntent client secret...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            clientSecret = @"pi_bad_secret_1234";
            completion(clientSecret, nil);
        });
    };
    
    // ...used with ApplePayContext
    [self _startApplePayForContextWithExpectedStatus:PKPaymentAuthorizationStatusFailure];
    
    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        // ...and results in an error
        XCTAssertEqual(status, STPPaymentStatusError);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, StripeDomain);
        [didCallCompletion fulfill];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCancelBeforePaymentIntentConfirmsCancels {
    // Cancelling Apple Pay *before* the context attempts to confirms the PI...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [self.context paymentAuthorizationViewControllerDidFinish:self.context.viewController]; // Simulate cancel before passing PI to the context
        // ...should never retrieve the PI (b/c it is cancelled before)
        completion(@"A 'client secret' that triggers an exception if fetched", nil);
    };
    
    [self.context paymentAuthorizationViewController:self.context.viewController
                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay

    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        // ...and results in a 'user cancel' status
        XCTAssertEqual(status, STPPaymentStatusUserCancellation);
        XCTAssertNil(error);
        [didCallCompletion fulfill];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCancelAfterPaymentIntentConfirmsStillSucceeds {
    // Cancelling Apple Pay *after* the context attempts to confirms the PI...
    id apiClientMock = OCMPartialMock(self.apiClient);
    OCMStub([apiClientMock confirmPaymentIntentWithParams:[OCMArg any] completion:[OCMArg any]]).andForwardToRealObject().andDo(^(NSInvocation *__unused invocation) {
        [self.context paymentAuthorizationViewControllerDidFinish:self.context.viewController]; // Simulate cancel after PI confirm begins
    });
    
    __block NSString *clientSecret;
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };
    
    [self.context paymentAuthorizationViewController:self.context.viewController
                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay
    
    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        XCTAssertEqual(status, STPPaymentStatusSuccess);
        XCTAssertNil(error);
        
        // ...and results in a successful PI
        [self.apiClient retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * paymentIntentRetrieveError) {
            XCTAssertNil(paymentIntentRetrieveError);
            XCTAssert(paymentIntent.status == STPPaymentIntentStatusSucceeded);
            [didCallCompletion fulfill];
        }];
    };
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Helper

/// Simulates user tapping 'Pay' button in Apple Pay sheet
- (void)_startApplePayForContextWithExpectedStatus:(PKPaymentAuthorizationStatus)expectedStatus {
    // When the user taps 'Pay', PKPaymentAuthorizationViewController calls `didAuthorizePayment:completion:`
    // After you call its completion block, it calls `paymentAuthorizationViewControllerDidFinish:`
    XCTestExpectation *didCallAuthorizePaymentCompletion = [self expectationWithDescription:@"ApplePayContext called completion block of paymentAuthorizationViewController:didAuthorizePayment:completion:"];
    [self.context paymentAuthorizationViewController:self.context.viewController didAuthorizePayment:[STPFixtures simulatorApplePayPayment] handler:^(PKPaymentAuthorizationResult * _Nonnull result) {
        XCTAssertEqual(expectedStatus, result.status);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.context paymentAuthorizationViewControllerDidFinish:self.context.viewController];
            [didCallAuthorizePaymentCompletion fulfill];
        });
    }];
}

@end
