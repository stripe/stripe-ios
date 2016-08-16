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
#import "NSDecimalNumber+Stripe_Currency.h"

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

- (NSArray<PKPaymentSummaryItem *> *)testSummaryItems {
    return @[[PKPaymentSummaryItem summaryItemWithLabel:@"First item"
                                                 amount:[NSDecimalNumber decimalNumberWithMantissa:20 exponent:0 isNegative:NO]],
             [PKPaymentSummaryItem summaryItemWithLabel:@"Second item"
                                                 amount:[NSDecimalNumber decimalNumberWithMantissa:90 exponent:0 isNegative:NO]],
             [PKPaymentSummaryItem summaryItemWithLabel:@"Discount"
                                                 amount:[NSDecimalNumber decimalNumberWithMantissa:10 exponent:0 isNegative:YES]],
             [PKPaymentSummaryItem summaryItemWithLabel:@"Total"
                                                 amount:[NSDecimalNumber decimalNumberWithMantissa:100 exponent:0 isNegative:NO]]
             ];
}

- (void)testBuildPaymentRequest_summaryItems {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentSummaryItems = [self testSummaryItems];
    PKPaymentRequest *request = [context buildPaymentRequest];
    
    XCTAssertTrue([request.paymentSummaryItems isEqualToArray:context.paymentSummaryItems]);
}

- (void)testSetPaymentAmount_generateSummaryItems {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentAmount = 10000;
    context.paymentCurrency = @"USD";
    NSDecimalNumber *itemTotalAmount = context.paymentSummaryItems.lastObject.amount;
    NSDecimalNumber *correctTotalAmount = [NSDecimalNumber stp_decimalNumberWithAmount:context.paymentAmount
                                                                              currency:context.paymentCurrency];
    
    XCTAssertTrue([itemTotalAmount isEqualToNumber:correctTotalAmount]);
}

- (void)testSummaryItems_generateAmountDecimalCurrency {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentSummaryItems = [self testSummaryItems];
    context.paymentCurrency = @"USD";
    XCTAssertTrue(context.paymentAmount == 10000);
}

- (void)testSummaryItems_generateAmountNoDecimalCurrency {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithAPIAdapter:[TestSTPBackendAPIAdapter new]];
    context.paymentSummaryItems = [self testSummaryItems];
    context.paymentCurrency = @"JPY";
    XCTAssertTrue(context.paymentAmount == 100);
}

@end
