//
//  STPPaymentMethodNetBankingParamsTest.m
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import StripeCoreTestUtils;
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodNetBankingParamsTests : XCTestCase

@end

@implementation STPPaymentMethodNetBankingParamsTests

- (void)testCreateNetBankingPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingINPublishableKey];
    STPPaymentMethodNetBankingParams *netbankingParams = [STPPaymentMethodNetBankingParams new];
    netbankingParams.bank = @"icici";
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";
  
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithNetBanking:netbankingParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];
  
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method NetBanking create"];
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNil(error, @"Unexpected error creating NetBanking PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create NetBanking PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeNetBanking, @"Incorrect PaymentMethod type");
        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");
        // UPI Details
        XCTAssertNotNil(paymentMethod.netBanking, @"Missing NetBanking");
        XCTAssertEqualObjects(paymentMethod.netBanking.bank, @"icici", @"Incorrect bank value");
    }];
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}
@end
