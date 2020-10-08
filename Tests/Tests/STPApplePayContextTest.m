//
//  STPApplePayContextTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPApplePayContext.h"
#import "STPFixtures.h"
#import "Stripe.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"

@interface STPApplePayContext (Private) <PKPaymentAuthorizationViewControllerDelegate>
- (STPPaymentIntentShippingDetailsParams *)_shippingDetailsFromPKPayment:(PKPayment *)payment;
@end

@interface STPApplePayTestDelegateiOS11 : NSObject <STPApplePayContextDelegate>
@end

#pragma mark - STPApplePayTestDelegateiOS11

@implementation STPApplePayTestDelegateiOS11

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingContact:(__unused PKContact *)contact handler:(__unused void (^)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion{
    completion([PKPaymentRequestShippingContactUpdate new]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didSelectShippingMethod:(__unused PKShippingMethod *)shippingMethod handler:(__unused void (^)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion{
    completion([PKPaymentRequestShippingMethodUpdate new]);
}

- (void)applePayContext:(__unused STPApplePayContext *)context didCompleteWithStatus:(__unused STPPaymentStatus)status error:(__unused NSError *)error {}

- (void)applePayContext:(nonnull STPApplePayContext *)context didCreatePaymentMethod:(nonnull STPPaymentMethod *)paymentMethod paymentInformation:(nonnull PKPayment *)paymentInformation completion:(nonnull STPIntentClientSecretCompletionBlock)completion {
    
}

@end

@interface STPApplePayContextTest : XCTestCase
@end

@implementation STPApplePayContextTest

- (void)testiOS11ApplePayDelegateMethodsForwarded {
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

- (void)testConvertsShippingDetails {
    STPApplePayTestDelegateiOS11 *delegate = [STPApplePayTestDelegateiOS11 new];
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:@"foo" country:@"US" currency:@"USD"];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];
    STPApplePayContext *context = [[STPApplePayContext alloc] initWithPaymentRequest:request delegate:delegate];
    
    PKPayment *payment = [STPFixtures simulatorApplePayPayment];
    PKContact *shipping = [PKContact new];
    shipping.name = [[NSPersonNameComponentsFormatter new] personNameComponentsFromString:@"Jane Doe"];
    shipping.phoneNumber = [[CNPhoneNumber alloc] initWithStringValue:@"555-555-5555"];
    CNMutablePostalAddress *address = [CNMutablePostalAddress new];
    address.street = @"510 Townsend St";
    address.city = @"San Francisco";
    address.state = @"CA";
    address.ISOCountryCode = @"US";
    address.postalCode = @"94105";
    shipping.postalAddress = address;
    [payment performSelector:@selector(setShippingContact:) withObject:shipping];
    
    STPPaymentIntentShippingDetailsParams *shippingParams = [context _shippingDetailsFromPKPayment:payment];
    XCTAssertNotNil(shippingParams);
    XCTAssertEqualObjects(shippingParams.name, @"Jane Doe");
    XCTAssertNil(shippingParams.carrier);
    XCTAssertEqualObjects(shippingParams.phone, @"555-555-5555");
    XCTAssertNil(shippingParams.trackingNumber);

    XCTAssertEqualObjects(shippingParams.address.line1, @"510 Townsend St");
    XCTAssertNil(shippingParams.address.line2);
    XCTAssertEqualObjects(shippingParams.address.city, @"San Francisco");
    XCTAssertEqualObjects(shippingParams.address.state, @"CA");
    XCTAssertEqualObjects(shippingParams.address.country, @"US");
    XCTAssertEqualObjects(shippingParams.address.postalCode, @"94105");
}

#pragma clang diagnostic pop

@end
