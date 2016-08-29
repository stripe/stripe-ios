//
//  STPPaymentContextAmountModelTest.m
//  Stripe
//
//  Created by Ben Guo on 9/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentContextAmountModel.h"

@interface STPPaymentContextAmountModelTest : XCTestCase

@end

@implementation STPPaymentContextAmountModelTest

- (void)testPaymentSummaryItems_paymentAmount_noShippingMethod {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:nil];
    XCTAssertEqual((int)[items count], 1);
    PKPaymentSummaryItem *firstItem = [items firstObject];
    XCTAssertEqualObjects(firstItem.label, @"Foo Company");
    XCTAssertEqualObjects(firstItem.amount, [NSDecimalNumber decimalNumberWithString:@"1.00"]);
}

- (void)testPaymentSummaryItems_paymentAmount_shippingMethod {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    STPShippingMethod *method = [[STPShippingMethod alloc] initWithAmount:599 currency:@"usd" label:@"FedEx" detail:@"foo" identifier:@"123"];
    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:method];
    XCTAssertEqual((int)[items count], 2);
    PKPaymentSummaryItem *item1 = items[0];
    XCTAssertEqualObjects(item1.label, @"FedEx");
    XCTAssertEqualObjects(item1.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);

    PKPaymentSummaryItem *item2 = items[1];
    XCTAssertEqualObjects(item2.label, @"Foo Company");
    XCTAssertEqualObjects(item2.amount, [NSDecimalNumber decimalNumberWithString:@"6.99"]);
}

- (void)testPaymentSummaryItems_summaryItems_shippingMethod {
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem new];
    item1.amount = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    item1.label = @"foo";
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem new];
    item2.amount = [NSDecimalNumber decimalNumberWithString:@"9.00"];
    item2.label = @"baz";
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem new];
    item3.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    item3.label = @"bar";
    STPShippingMethod *method = [[STPShippingMethod alloc] initWithAmount:599 currency:@"usd" label:@"FedEx" detail:@"foo" identifier:@"123"];
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:@[item1, item2, item3]];

    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:method];
    XCTAssertEqual((int)[items count], 4);
    PKPaymentSummaryItem *firstItem = items[0];
    XCTAssertEqualObjects(firstItem.label, @"foo");
    XCTAssertEqualObjects(firstItem.amount, [NSDecimalNumber decimalNumberWithString:@"1.00"]);
    PKPaymentSummaryItem *secondItem = items[1];
    XCTAssertEqualObjects(secondItem.label, @"baz");
    XCTAssertEqualObjects(secondItem.amount, [NSDecimalNumber decimalNumberWithString:@"9.00"]);
    PKPaymentSummaryItem *shippingItem = items[2];
    XCTAssertEqualObjects(shippingItem.label, @"FedEx");
    XCTAssertEqualObjects(shippingItem.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);
    PKPaymentSummaryItem *totalItem = items[3];
    XCTAssertEqualObjects(totalItem.label, @"bar");
    XCTAssertEqualObjects(totalItem.amount, [NSDecimalNumber decimalNumberWithString:@"15.99"]);
}

- (void)testPaymentAmount_summaryItems_noShippingMethod {
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem new];
    item1.amount = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    item1.label = @"foo";
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem new];
    item2.amount = [NSDecimalNumber decimalNumberWithString:@"9.00"];
    item2.label = @"foo";
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem new];
    item3.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    item3.label = @"bar";
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:@[item1, item2, item3]];

    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:nil];
    XCTAssertEqual((int)[items count], 3);
    PKPaymentSummaryItem *secondToLast = items[1];
    XCTAssertEqualObjects(secondToLast.label, @"foo");
    XCTAssertEqualObjects(secondToLast.amount, [NSDecimalNumber decimalNumberWithString:@"9.00"]);
    PKPaymentSummaryItem *totalItem = items[2];
    XCTAssertEqualObjects(totalItem.label, @"bar");
    XCTAssertEqualObjects(totalItem.amount, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
}

- (void)testPaymentAmount_jpy {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    STPShippingMethod *method = [[STPShippingMethod alloc] initWithAmount:599 currency:@"jpy" label:@"bar" detail:@"foo" identifier:@"123"];
    NSInteger amount = [sut paymentAmountWithCurrency:@"jpy" shippingMethod:method];
    XCTAssertEqual(amount, 699);
}

@end
