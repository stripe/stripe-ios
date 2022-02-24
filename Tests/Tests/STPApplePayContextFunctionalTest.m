//
//  STPApplePayContextFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import StripeCoreTestUtils;
#import "STPTestingAPIClient.h"

#import "STPFixtures.h"
#import "StripeiOS_Tests-Swift.h"
@import OHHTTPStubs;


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


@interface STPApplePayContext(Testing) <PKPaymentAuthorizationControllerDelegate>
@property (nonatomic, nullable) PKPaymentAuthorizationController *authorizationController;
@end

API_AVAILABLE(ios(13.0))
@interface STPApplePayContextFunctionalTest : XCTestCase
@property (nonatomic) STPApplePayContextFunctionalTestAPIClient *apiClient;
@property (nonatomic) STPTestApplePayContextDelegate *delegate;
@property (nonatomic) STPApplePayContext *context;

@end

@interface STPTestPKPaymentAuthorizationController : PKPaymentAuthorizationController
@end

@implementation STPTestPKPaymentAuthorizationController

// Stub dismissViewControllerAnimated: to just call its completion block
- (void)dismissWithCompletion:(void (^)(void))completion {
    completion();
}

@end

@implementation STPApplePayContextFunctionalTest

- (void)setUp {
    self.delegate = [STPTestApplePayContextDelegate new];
    if (@available(iOS 13.0, *)) {
        STPApplePayContextFunctionalTestAPIClient *apiClient = [[STPApplePayContextFunctionalTestAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [apiClient setupStubs];
        apiClient.applePayContext = self.context;
        self.apiClient = apiClient;
    } else {
        XCTSkip("Unsupported iOS version");
    }
    
    self.context = [[STPApplePayContext alloc] initWithPaymentRequest:[STPFixtures applePayRequest] delegate:self.delegate];
    self.apiClient.applePayContext = self.context;
    self.context.apiClient = self.apiClient;
    self.context._applePayContext.authorizationController = [[STPTestPKPaymentAuthorizationController alloc] init];
}

- (void)tearDown {
    [HTTPStubs removeAllStubs];
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
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
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
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
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
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCompletesSetupIntent {
    __block NSString *clientSecret;
    // An automatic confirmation SI...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
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
        [self.apiClient retrieveSetupIntentWithClientSecret:clientSecret completion:^(STPSetupIntent * _Nullable setupIntent, NSError *setupIntentRetrieveError) {
            XCTAssertNil(setupIntentRetrieveError);
            XCTAssert(setupIntent.status == STPSetupIntentStatusSucceeded);
            [didCallCompletion fulfill];
        }];
    };

    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Error tests
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
        XCTAssertEqualObjects(error.domain, [STPError stripeDomain]);
        [didCallCompletion fulfill];
    };
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testBadSetupIntentClientSecretErrors {
    __block NSString *clientSecret;
    // An invalid SetupIntent client secret...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            clientSecret = @"seti_bad_secret_1234";
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
        XCTAssertEqualObjects(error.domain, [STPError stripeDomain]);
        [didCallCompletion fulfill];
    };

    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Cancel tests
- (void)testCancelBeforeIntentConfirmsCancels {
    // Cancelling Apple Pay *before* the context attempts to confirms the PI/SI...
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [self.context._applePayContext paymentAuthorizationControllerDidFinish:self.context._applePayContext.authorizationController]; // Simulate cancel before passing PI to the context
        // ...should never retrieve the PI (b/c it is cancelled before)
        completion(@"A 'client secret' that triggers an exception if fetched", nil);
    };
    
    [self.context._applePayContext paymentAuthorizationController:self.context._applePayContext.authorizationController
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
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCancelAfterPaymentIntentConfirmsStillSucceeds {
    // Cancelling Apple Pay *after* the context attempts to confirm the PI...
    self.apiClient.shouldSimulateCancelAfterConfirmBegins = true;
    
    __block NSString *clientSecret;
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };
    
    [self.context._applePayContext paymentAuthorizationController:self.context._applePayContext.authorizationController
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
    
    [self waitForExpectationsWithTimeout:20.0 handler:nil]; // give this a longer timeout, it tends to take a while
}

- (void)testCancelAfterSetupIntentConfirmsStillSucceeds {
    // Cancelling Apple Pay *after* the context attempts to confirm the SI...
    self.apiClient.shouldSimulateCancelAfterConfirmBegins = true;

    __block NSString *clientSecret;
    STPTestApplePayContextDelegate *delegate = self.delegate;
    delegate.didCreatePaymentMethodDelegateMethod = ^(__unused STPPaymentMethod *paymentMethod, __unused PKPayment *paymentInformation, STPIntentClientSecretCompletionBlock completion) {
        [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil completion:^(NSString * _Nullable _clientSecret, NSError * __unused error) {
            XCTAssertNotNil(_clientSecret);
            clientSecret = _clientSecret;
            completion(clientSecret, nil);
        }];
    };

    [self.context._applePayContext paymentAuthorizationController:self.context._applePayContext.authorizationController
                                 didAuthorizePayment:[STPFixtures simulatorApplePayPayment]
                                             handler:^(PKPaymentAuthorizationResult * __unused _Nonnull result) {}]; // Simulate user tapping 'Pay' button in Apple Pay

    // ...calls applePayContext:didCompleteWithStatus:error:
    XCTestExpectation *didCallCompletion = [self expectationWithDescription:@"applePayContext:didCompleteWithStatus: called"];
    delegate.didCompleteDelegateMethod = ^(STPPaymentStatus status, NSError *error) {
        XCTAssertEqual(status, STPPaymentStatusSuccess);
        XCTAssertNil(error);

        // ...and results in a successful SI
        [self.apiClient retrieveSetupIntentWithClientSecret:clientSecret completion:^(STPSetupIntent * _Nullable setupIntent, NSError * setupIntentRetrieveError) {
            XCTAssertNil(setupIntentRetrieveError);
            XCTAssert(setupIntent.status == STPSetupIntentStatusSucceeded);
            [didCallCompletion fulfill];
        }];
    };

    [self waitForExpectationsWithTimeout:20.0 handler:nil]; // give this a longer timeout, it tends to take a while
}


#pragma mark - Helper

/// Simulates user tapping 'Pay' button in Apple Pay sheet
- (void)_startApplePayForContextWithExpectedStatus:(PKPaymentAuthorizationStatus)expectedStatus {
    // When the user taps 'Pay', PKPaymentAuthorizationController calls `didAuthorizePayment:completion:`
    // After you call its completion block, it calls `paymentAuthorizationControllerDidFinish:`
    XCTestExpectation *didCallAuthorizePaymentCompletion = [self expectationWithDescription:@"ApplePayContext called completion block of paymentAuthorizationController:didAuthorizePayment:completion:"];
    [self.context._applePayContext paymentAuthorizationController:self.context._applePayContext.authorizationController didAuthorizePayment:[STPFixtures simulatorApplePayPayment] handler:^(PKPaymentAuthorizationResult * _Nonnull result) {
        XCTAssertEqual(expectedStatus, result.status);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.context._applePayContext paymentAuthorizationControllerDidFinish:self.context._applePayContext.authorizationController];
            [didCallAuthorizePaymentCompletion fulfill];
        });
    }];
}

@end
