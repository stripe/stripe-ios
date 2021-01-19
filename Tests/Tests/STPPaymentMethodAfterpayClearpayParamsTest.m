//
//  STPPaymentMethodAfterpayClearpayParamsTest.m
//  StripeiOS Tests
//
//  Created by Ali Riaz on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodAfterpayClearpayParamsTest : XCTestCase

@end

@implementation STPPaymentMethodAfterpayClearpayParamsTest

- (void)testCreateAfterpayClearpayPaymentMethod {
  STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
  STPPaymentMethodAfterpayClearpayParams *afterpayClearpayParams = [STPPaymentMethodAfterpayClearpayParams new];

  STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
  billingDetails.name = @"Jenny Rosen";
  billingDetails.email = @"jrosen@example.com";
  billingDetails.address = [STPPaymentMethodAddress new];
  billingDetails.address.line1 = @"510 Townsend St.";
  billingDetails.address.postalCode = @"94102";
  billingDetails.address.country = @"US";
  
  STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithAfterpayClearpay:afterpayClearpayParams
                                                                  billingDetails:billingDetails
                                                                        metadata:@{@"test_key": @"test_value"}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method AfterpayClearpay create"];
  
  [client createPaymentMethodWithParams:params completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
    [expectation fulfill];
    
    XCTAssertNil(error, @"Unexpected error creating AfterpayClearpay Payment Method %@a", error);
    XCTAssertNotNil(paymentMethod, @"Failed to create AfterpayClearpay PaymentMethod");
    XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
    XCTAssertNotNil(paymentMethod.created, @"Missing created");
    XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
    XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeAfterpayClearpay, @"Incorrect PaymentMethod type");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertNil(paymentMethod.metadata, @"Metadata is not returned.");
#pragma clang diagnostic pop
    
    // Billing Details
    XCTAssertEqualObjects(paymentMethod.billingDetails.email, @"jrosen@example.com", @"Incorrect email");
    XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");
    XCTAssertEqualObjects(paymentMethod.billingDetails.address.line1, @"510 Townsend St.", @"Incorrect address");
    XCTAssertEqualObjects(paymentMethod.billingDetails.address.postalCode, @"94102", @"Incorrect address");
    XCTAssertEqualObjects(paymentMethod.billingDetails.address.country, @"US", @"Incorrect address");
    
    XCTAssertNotNil(paymentMethod.afterpayClearpay, @"");
  }];
  
  [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];

}

@end
