//
//  STPApplePayContextTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPApplePayContext.h"
#import "Stripe.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

@interface STPApplePayContext (Private) <PKPaymentAuthorizationViewControllerDelegate>
@end

@interface STPApplePayTestDelegateiOS11 : NSObject <STPApplePayContextDelegate>
@end

#pragma mark - STPApplePayTestDelegateiOS11

@implementation STPApplePayTestDelegateiOS11

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingContact:(__unused PKContact *)contact handler:(__unused void (^)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion  API_AVAILABLE(ios(11.0)){
    completion([PKPaymentRequestShippingContactUpdate new]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingMethod:(__unused PKShippingMethod *)shippingMethod handler:(__unused void (^)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion  API_AVAILABLE(ios(11.0)){
    completion([PKPaymentRequestShippingMethodUpdate new]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(__unused STPPaymentStatus)status error:(__unused NSError *)error {}
- (void)applePayContext:(__unused STPApplePayContext *)context didCreatePaymentMethod:(__unused NSString *)paymentMethodID completion:(__unused STPIntentClientSecretCompletionBlock)completion {}

@end

#pragma mark - STPApplePayTestDelegateiOS10

@interface STPApplePayTestDelegateiOS10 : NSObject <STPApplePayContextDelegate>
@end

@implementation STPApplePayTestDelegateiOS10

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingContact:(__unused PKContact *)contact completion:(nonnull void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    completion(PKPaymentAuthorizationStatusSuccess, @[], @[]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingMethod:(__unused PKShippingMethod *)shippingMethod completion:(nonnull void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    completion(PKPaymentAuthorizationStatusSuccess, @[]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(__unused STPPaymentStatus)status error:(__unused NSError *)error {}
- (void)applePayContext:(__unused STPApplePayContext *)context didCreatePaymentMethod:(__unused NSString *)paymentMethodID completion:(__unused STPIntentClientSecretCompletionBlock)completion {}

@end


@interface STPApplePayContextTest : XCTestCase
@end

@implementation STPApplePayContextTest

- (void)testiOS11ApplePayDelegateMethodsForwarded API_AVAILABLE(ios(11.0)) {
    if (@available(iOS 11, *)) {
    } else {
        return;
    }
    // With a user that only implements iOS 11 delegate methods...
    STPApplePayTestDelegateiOS11 *delegate = [STPApplePayTestDelegateiOS11 new];
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:@"foo" country:@"US" currency:@"USD"];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];
    STPApplePayContext *context = [[STPApplePayContext alloc] initWithPaymentRequest:request delegate:delegate];
    XCTAssertNotNil(context);
    
    // ...the context should respondToSelector appropriately...
    XCTAssertTrue([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingContact:handler:)]);
    XCTAssertFalse([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingContact:completion:)]);
    
    XCTAssertTrue([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingMethod:handler:)]);
    XCTAssertFalse([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingMethod:completion:)]);
    
    // ...and forward the PassKit delegate method to its delegate
    PKPaymentAuthorizationViewController *vc;
    PKContact *contact;
    XCTestExpectation *shippingContactExpectation = [self expectationWithDescription:@"didSelectShippingContact forwarded"];
    [context paymentAuthorizationViewController:vc didSelectShippingContact:contact handler:^(PKPaymentRequestShippingContactUpdate * _Nonnull update) {
        [shippingContactExpectation fulfill];
    }];
    
    PKShippingMethod *method;
    XCTestExpectation *shippingMethodExpectation = [self expectationWithDescription:@"didSelectShippingMethod forwarded"];
    [context paymentAuthorizationViewController:vc didSelectShippingMethod:method handler:^(PKPaymentRequestShippingMethodUpdate * _Nonnull update) {
        [shippingMethodExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testiOS10ApplePayDelegateMethodsForwarded {
    // With a user that only implements iOS 10 delegate methods...
    STPApplePayTestDelegateiOS10 *delegate = [STPApplePayTestDelegateiOS10 new];
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:@"foo" country:@"US" currency:@"USD"];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];
    STPApplePayContext *context = [[STPApplePayContext alloc] initWithPaymentRequest:request delegate:delegate];
    XCTAssertNotNil(context);

    // ...the context should respondToSelector appropriately...
    XCTAssertTrue([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingContact:completion:)]);
    XCTAssertFalse([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingContact:handler:)]);
    
    XCTAssertTrue([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingMethod:completion:)]);
    XCTAssertFalse([context respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingMethod:handler:)]);
    
    // ...and forward the PassKit delegate method to its delegate
    PKPaymentAuthorizationViewController *vc;
    PKContact *contact;
    XCTestExpectation *shippingContactExpectation = [self expectationWithDescription:@"didSelectShippingContact forwarded"];
    [context paymentAuthorizationViewController:vc didSelectShippingContact:contact completion:^(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> * _Nonnull shippingMethods, NSArray<PKPaymentSummaryItem *> * _Nonnull summaryItems) {
        [shippingContactExpectation fulfill];
    }];
    
    PKShippingMethod *method;
    XCTestExpectation *shippingMethodExpectation = [self expectationWithDescription:@"didSelectShippingMethod forwarded"];
    [context paymentAuthorizationViewController:vc didSelectShippingMethod:method completion:^(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> * _Nonnull summaryItems) {
        [shippingMethodExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}


#pragma clang diagnostic pop

@end
