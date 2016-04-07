//
//  STPPaymentRequestTests.m
//  Stripe
//
//  Created by Jack Flintermann on 4/7/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentRequest.h"
#import "STPLineItem.h"

@interface STPPaymentRequestTests : XCTestCase

@end

@implementation STPPaymentRequestTests

- (void)testAsPKPayment {
    STPPaymentRequest *paymentRequest = [[STPPaymentRequest alloc] init];
    XCTAssertNil([paymentRequest asPKPayment]);
    
    paymentRequest.appleMerchantId = @"something";
    paymentRequest.lineItems = @[];
    XCTAssertNil([paymentRequest asPKPayment]);
    
    paymentRequest.lineItems = @[[[STPLineItem alloc] initWithLabel:@"Test" amount:[NSDecimalNumber zero]]];
    XCTAssertNil([paymentRequest asPKPayment]);
    
    paymentRequest.lineItems = @[[[STPLineItem alloc] initWithLabel:@"Test" amount:[NSDecimalNumber one]]];
    paymentRequest.merchantName = @"Test Merchant";
    PKPaymentRequest *pkPaymentRequest = [paymentRequest asPKPayment];
    XCTAssertNotNil(pkPaymentRequest);
    NSArray *expectedLineItems = @[
       [PKPaymentSummaryItem summaryItemWithLabel:@"Test" amount:[NSDecimalNumber one]],
       [PKPaymentSummaryItem summaryItemWithLabel:@"Test Merchant" amount:[NSDecimalNumber one]],
    ];
    XCTAssertEqualObjects(pkPaymentRequest.paymentSummaryItems, expectedLineItems);
}

@end
