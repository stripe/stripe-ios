//
//  STPPaymentContextTest.m
//  Stripe
//
//  Created by Brian Dorfman on 8/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAPIClient.h"
#import "STPPaymentContext.h"
#import "TestSTPBackendAPIAdapter.h"

@interface STPPaymentContext (Testing)
- (PKPaymentRequest *)buildPaymentRequest;
@end

@interface STPPaymentContextTest : XCTestCase
@end

@implementation STPPaymentContextTest

- (void)setUp {
    [super setUp];
    [Stripe setDefaultPublishableKey:@"test"];
    [STPPaymentConfiguration sharedConfiguration].appleMerchantIdentifier = @"testMerchantId";
}

- (void)testBuildPaymentRequest_totalAmount {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 150;
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([[request.paymentSummaryItems lastObject].amount isEqual:[NSDecimalNumber decimalNumberWithString:@"1.50"]],
                  @"PKPayment total is not equal to STPPaymentContext amount");
}

- (void)testBuildPaymentRequest_USDDefault {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    PKPaymentRequest *request = [context buildPaymentRequest];
    
    XCTAssertTrue([request.currencyCode isEqualToString:@"USD"], 
                  @"Default PKPaymentRequest currency code is not USD");
}

- (void)testBuildPaymentRequest_currency {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    context.paymentCurrency = @"GBP";
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([request.currencyCode isEqualToString:@"GBP"], 
                  @"PKPaymentRequest currency code is not equal to STPPaymentContext currency");
}

- (void)testBuildPaymentRequest_uppercaseCurrency {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 100;
    context.paymentCurrency = @"eur";
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([request.currencyCode isEqualToString:@"EUR"], 
                  @"PKPaymentRequest currency code is not uppercased");
}



@end
