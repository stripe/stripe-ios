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

- (void)testAmountToSummaryItems_noShippingMethod {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:nil];

    XCTAssertEqual((int)[items count], 1);
    PKPaymentSummaryItem *firstItem = [items firstObject];
    XCTAssertEqualObjects(firstItem.label, @"Foo Company");
    XCTAssertEqualObjects(firstItem.amount, [NSDecimalNumber decimalNumberWithString:@"1.00"]);
}

- (void)testAmountToSummaryItems_shippingMethod {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";

    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:method];
    XCTAssertEqual((int)[items count], 2);
    PKPaymentSummaryItem *item1 = items[0];
    XCTAssertEqualObjects(item1.label, @"FedEx");
    XCTAssertEqualObjects(item1.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);
    PKPaymentSummaryItem *item2 = items[1];
    XCTAssertEqualObjects(item2.label, @"Foo Company");
    XCTAssertEqualObjects(item2.amount, [NSDecimalNumber decimalNumberWithString:@"6.99"]);
}

- (void)testSummaryItemsToSummaryItems_shippingMethod {
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem new];
    item1.amount = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    item1.label = @"foo";
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem new];
    item2.amount = [NSDecimalNumber decimalNumberWithString:@"9.00"];
    item2.label = @"bar";
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem new];
    item3.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    item3.label = @"baz";
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:@[item1, item2, item3]];

    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:method];
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

- (void)testSummaryItemsToSummaryItems_noShippingMethod {
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem new];
    item1.amount = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    item1.label = @"foo";
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem new];
    item2.amount = [NSDecimalNumber decimalNumberWithString:@"9.00"];
    item2.label = @"bar";
    PKPaymentSummaryItem *item3 = [PKPaymentSummaryItem new];
    item3.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    item3.label = @"baz";
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithPaymentSummaryItems:@[item1, item2, item3]];

    NSArray<PKPaymentSummaryItem *> *items = [sut paymentSummaryItemsWithCurrency:@"usd" companyName:@"Foo Company" shippingMethod:nil];
    XCTAssertEqual((int)[items count], 3);
    PKPaymentSummaryItem *resultItem1 = items[0];
    XCTAssertEqualObjects(resultItem1.label, @"foo");
    XCTAssertEqualObjects(resultItem1.amount, [NSDecimalNumber decimalNumberWithString:@"1.00"]);
    PKPaymentSummaryItem *resultItem2 = items[1];
    XCTAssertEqualObjects(resultItem2.label, @"bar");
    XCTAssertEqualObjects(resultItem2.amount, [NSDecimalNumber decimalNumberWithString:@"9.00"]);
    PKPaymentSummaryItem *resultItem3 = items[2];
    XCTAssertEqualObjects(resultItem3.label, @"baz");
    XCTAssertEqualObjects(resultItem3.amount, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
}

- (void)testAmountToAmount_shippingMethod_usd {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    NSInteger amount = [sut paymentAmountWithCurrency:@"usd" shippingMethod:method];
    XCTAssertEqual(amount, 699);
}

- (void)testAmountToAmount_shippingMethod_jpy {
    STPPaymentContextAmountModel *sut = [[STPPaymentContextAmountModel alloc] initWithAmount:100];
    PKShippingMethod *method = [PKShippingMethod new];
    method.amount = [NSDecimalNumber decimalNumberWithString:@"599"];
    method.label = @"FedEx";
    method.detail = @"foo";
    method.identifier = @"123";
    NSInteger amount = [sut paymentAmountWithCurrency:@"jpy" shippingMethod:method];
    XCTAssertEqual(amount, 699);
}

@end
