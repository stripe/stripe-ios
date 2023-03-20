//
//  STPPaymentContextApplePayTest.m
//  Stripe
//
//  Created by Brian Dorfman on 8/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "STPFixtures.h"
#import "STPMocks.h"


@interface STPPaymentContext (Testing)
@property (nonatomic) PKShippingMethod *selectedShippingMethod;
- (PKPaymentRequest *)buildPaymentRequest;
@end

/**
 These tests cover STPPaymentContext's Apple Pay specific behavior:
 - building a PKPaymentRequest
 - determining paymentSummaryItems
 */
@interface STPPaymentContextApplePayTest : XCTestCase
@end

@implementation STPPaymentContextApplePayTest

- (STPPaymentContext *)buildPaymentContext {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.appleMerchantIdentifier = @"fake_merchant_id";
    STPTheme *theme = [STPTheme defaultTheme];
    STPCustomerContext *customerContext = [STPMocks staticCustomerContext];
    STPPaymentContext *paymentContext = [[STPPaymentContext alloc] initWithCustomerContext:customerContext
                                                                             configuration:config
                                                                                     theme:theme];
    return paymentContext;
}

#pragma mark - buildPaymentRequest

- (void)testBuildPaymentRequest_totalAmount {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 150;
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([[request.paymentSummaryItems lastObject].amount isEqual:[NSDecimalNumber decimalNumberWithString:@"1.50"]],
                  @"PKPayment total is not equal to STPPaymentContext amount");
}

- (void)testBuildPaymentRequest_USDDefault {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 100;
    PKPaymentRequest *request = [context buildPaymentRequest];
    
    XCTAssertTrue([request.currencyCode isEqualToString:@"USD"], 
                  @"Default PKPaymentRequest currency code is not USD");
}

- (void)testBuildPaymentRequest_currency {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 100;
    context.paymentCurrency = @"GBP";
    PKPaymentRequest *request = [context buildPaymentRequest];

    XCTAssertTrue([request.currencyCode isEqualToString:@"GBP"], 
                  @"PKPaymentRequest currency code is not equal to STPPaymentContext currency");
}

- (void)testBuildPaymentRequest_uppercaseCurrency {
    STPPaymentContext *context = [self buildPaymentContext];
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
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentSummaryItems = [self testSummaryItems];
    PKPaymentRequest *request = [context buildPaymentRequest];
    
    XCTAssertTrue([request.paymentSummaryItems isEqualToArray:context.paymentSummaryItems]);
}

#pragma mark - paymentSummaryItems

- (void)testSetPaymentAmount_generateSummaryItems {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 10000;
    context.paymentCurrency = @"USD";
    NSDecimalNumber *itemTotalAmount = context.paymentSummaryItems.lastObject.amount;
    NSDecimalNumber *correctTotalAmount = [NSDecimalNumber stp_decimalNumberWithAmount:context.paymentAmount
                                                                              currency:context.paymentCurrency];
    
    XCTAssertTrue([itemTotalAmount isEqualToNumber:correctTotalAmount]);
}

- (void)testSetPaymentAmount_generateSummaryItemsShippingMethod {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 100;
    context.configuration.companyName = @"Foo Company";
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    context.selectedShippingMethod = method;

    NSArray<PKPaymentSummaryItem *> *items = [context paymentSummaryItems];
    XCTAssertEqual((int)[items count], 2);
    PKPaymentSummaryItem *item1 = items[0];
    XCTAssertEqualObjects(item1.label, @"FedEx");
    XCTAssertEqualObjects(item1.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);
    PKPaymentSummaryItem *item2 = items[1];
    XCTAssertEqualObjects(item2.label, @"Foo Company");
    XCTAssertEqualObjects(item2.amount, [NSDecimalNumber decimalNumberWithString:@"6.99"]);
}

- (void)testSummaryItemsToSummaryItems_shippingMethod {
    STPPaymentContext *context = [self buildPaymentContext];
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem new];
    item1.amount = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    item1.label = @"foo";
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem new];
    item2.amount = [NSDecimalNumber decimalNumberWithString:@"9.00"];
    item2.label = @"bar";
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem new];
    item3.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    item3.label = @"baz";
    context.paymentSummaryItems = @[item1, item2, item3];
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    context.selectedShippingMethod = method;

    NSArray<PKPaymentSummaryItem *> *items = [context paymentSummaryItems];
    XCTAssertEqual((int)[items count], 4);
    PKPaymentSummaryItem *resultItem1 = items[0];
    XCTAssertEqualObjects(resultItem1.label, @"foo");
    XCTAssertEqualObjects(resultItem1.amount, [NSDecimalNumber decimalNumberWithString:@"1.00"]);
    PKPaymentSummaryItem *resultItem2 = items[1];
    XCTAssertEqualObjects(resultItem2.label, @"bar");
    XCTAssertEqualObjects(resultItem2.amount, [NSDecimalNumber decimalNumberWithString:@"9.00"]);
    PKPaymentSummaryItem *resultItem3 = items[2];
    XCTAssertEqualObjects(resultItem3.label, @"FedEx");
    XCTAssertEqualObjects(resultItem3.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);
    PKPaymentSummaryItem *resultItem4 = items[3];
    XCTAssertEqualObjects(resultItem4.label, @"baz");
    XCTAssertEqualObjects(resultItem4.amount, [NSDecimalNumber decimalNumberWithString:@"15.99"]);
}

- (void)testAmountToAmount_shippingMethod_usd {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentAmount = 100;
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    context.selectedShippingMethod = method;
    NSInteger amount = context.paymentAmount;
    XCTAssertEqual(amount, 699);
}

- (void)testSummaryItems_generateAmountDecimalCurrency {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentSummaryItems = [self testSummaryItems];
    context.paymentCurrency = @"USD";
    XCTAssertTrue(context.paymentAmount == 10000);
}

- (void)testSummaryItems_generateAmountNoDecimalCurrency {
    STPPaymentContext *context = [self buildPaymentContext];
    context.paymentSummaryItems = [self testSummaryItems];
    context.paymentCurrency = @"JPY";
    XCTAssertTrue(context.paymentAmount == 100);
}

@end
