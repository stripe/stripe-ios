//
//  STPPaymentMethodFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPNetworkStubbingTestCase.h"

@import Stripe;

@interface STPPaymentMethodFunctionalTest : STPNetworkStubbingTestCase

@end

@implementation STPPaymentMethodFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

- (void)testCreatePaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_dCyfhfyeO2CZkcvT5xyIDdJj"];
    STPPaymentMethodCardParams *card = [STPPaymentMethodCardParams new];
    card.number = @"4242424242424242";
    card.expMonth = @(10);
    card.expYear = @(2022);
    card.cvc = @"100";
    
    STPPaymentMethodAddress *billingAddress = [STPPaymentMethodAddress new];
    billingAddress.city = @"San Francisco";
    billingAddress.country = @"US";
    billingAddress.line1 = @"150 Townsend St";
    billingAddress.line2 = @"4th Floor";
    billingAddress.postalCode = @"94103";
    billingAddress.state = @"CA";
    
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.address = billingAddress;
    billingDetails.email = @"email@email.com";
    billingDetails.name = @"Isaac Asimov";
    billingDetails.phone = @"555-555-5555";
    
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithCard:card
                                                                 billingDetails:billingDetails
                                                                       metadata:@{@"test_key": @"test_value"}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
                                   XCTAssertNil(error);
                                   XCTAssertNotNil(paymentMethod);
                                   XCTAssertEqualObjects(paymentMethod.stripeId, @"pm_0EztlC589O8KAxCGeqEFbPVQ");
                                   XCTAssertEqualObjects(paymentMethod.created, [NSDate dateWithTimeIntervalSince1970:1564010438]);
                                   XCTAssertFalse(paymentMethod.liveMode);
                                   XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeCard);
                                   XCTAssertEqualObjects(paymentMethod.metadata, @{@"test_key": @"test_value"});
                                   
                                   // Billing Details
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.email, @"email@email.com");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Isaac Asimov");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.phone, @"555-555-5555");
                                   
                                   // Billing Details Address
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.line1, @"150 Townsend St");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.line2, @"4th Floor");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.city, @"San Francisco");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.country, @"US");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.state, @"CA");
                                   XCTAssertEqualObjects(paymentMethod.billingDetails.address.postalCode, @"94103");
                                   
                                   // Card
                                   XCTAssertEqual(paymentMethod.card.brand, STPCardBrandVisa);
                                   XCTAssertEqual(paymentMethod.card.checks.cvcCheck, STPPaymentMethodCardCheckResultUnchecked);
                                   XCTAssertEqual(paymentMethod.card.checks.addressLine1Check, STPPaymentMethodCardCheckResultUnchecked);
                                   XCTAssertEqual(paymentMethod.card.checks.addressPostalCodeCheck, STPPaymentMethodCardCheckResultUnchecked);
                                   XCTAssertEqualObjects(paymentMethod.card.country, @"US");
                                   XCTAssertEqual(paymentMethod.card.expMonth, 10);
                                   XCTAssertEqual(paymentMethod.card.expYear, 2022);
                                   XCTAssertEqualObjects(paymentMethod.card.funding, @"credit");
                                   XCTAssertEqualObjects(paymentMethod.card.last4, @"4242");
                                   XCTAssertTrue(paymentMethod.card.threeDSecureUsage.supported);
                                   [expectation fulfill];
                               }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
