//
//  STPShippingMethodTest.m
//  Stripe
//
//  Created by Ben Guo on 8/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPShippingMethod+Private.h"

@interface STPShippingMethodTest : XCTestCase

@end

@implementation STPShippingMethodTest

- (void)testAmountString {
    STPShippingMethod *methodUSD = [[STPShippingMethod alloc] initWithAmount:599 currency:@"usd" label:@"foo" detail:@"bar" identifier:@"123"];
    XCTAssertEqualObjects([methodUSD amountString], @"$5.99");
    STPShippingMethod *methodJPY = [[STPShippingMethod alloc] initWithAmount:599 currency:@"jpy" label:@"foo" detail:@"bar" identifier:@"456"];
    XCTAssertEqualObjects([methodJPY amountString], @"¥599");
}

- (void)testInitWithPKShippingMethod {
    PKShippingMethod *pkMethod = [PKShippingMethod new];
    pkMethod.amount = [NSDecimalNumber decimalNumberWithString:@"100"];
    pkMethod.label = @"foo";
    pkMethod.detail = @"bar";
    pkMethod.identifier = @"123";
    STPShippingMethod *stpMethod = [[STPShippingMethod alloc] initWithPKShippingMethod:pkMethod currency:@"usd"];
    XCTAssertEqual(stpMethod.amount, 10000);
    XCTAssertEqualObjects(stpMethod.currency, @"USD");
    XCTAssertEqualObjects(stpMethod.label, pkMethod.label);
    XCTAssertEqualObjects(stpMethod.detail, pkMethod.detail);
    XCTAssertEqualObjects(stpMethod.identifier, pkMethod.identifier);

    PKShippingMethod *pkMethodJPY = [PKShippingMethod new];
    pkMethodJPY.amount = [NSDecimalNumber decimalNumberWithString:@"100"];
    STPShippingMethod *stpMethodJPY = [[STPShippingMethod alloc] initWithPKShippingMethod:pkMethodJPY currency:@"jpy"];
    XCTAssertEqual(stpMethodJPY.amount, 100);
    XCTAssertEqualObjects(stpMethodJPY.currency, @"JPY");
}

- (void)testPKShippingMethod {
    STPShippingMethod *methodUSD = [[STPShippingMethod alloc] initWithAmount:599 currency:@"usd" label:@"foo" detail:@"bar" identifier:@"123"];
    PKShippingMethod *pkMethodUSD = [methodUSD pkShippingMethod];
    XCTAssertEqualObjects(pkMethodUSD.amount, [NSDecimalNumber decimalNumberWithString:@"5.99"]);

    STPShippingMethod *methodJPY = [[STPShippingMethod alloc] initWithAmount:599 currency:@"jpy" label:@"foo" detail:@"bar" identifier:@"123"];
    PKShippingMethod *pkMethodJPY = [methodJPY pkShippingMethod];
    XCTAssertEqualObjects(pkMethodJPY.amount, [NSDecimalNumber decimalNumberWithString:@"599"]);
}

- (void)testPKShippingMethods_selectedMethod {
    STPShippingMethod *method1 = [[STPShippingMethod alloc] initWithAmount:100 currency:@"usd" label:@"UPS" detail:@"foo" identifier:@"123"];
    STPShippingMethod *method2 = [[STPShippingMethod alloc] initWithAmount:200 currency:@"usd" label:@"FedEx" detail:@"bar" identifier:@"456"];
    NSArray<STPShippingMethod *>*methods = @[method1, method2];

    NSArray<PKShippingMethod *>*pkMethods = [STPShippingMethod pkShippingMethods:methods selectedMethod:method2];
    XCTAssertEqual((int)[pkMethods count], 2);
    XCTAssertEqualObjects(pkMethods[0].identifier, @"456");
    XCTAssertEqualObjects(pkMethods[1].identifier, @"123");
}

- (void)testPKShippingMethods_selectedMethodNotFound {
    STPShippingMethod *method1 = [[STPShippingMethod alloc] initWithAmount:100 currency:@"usd" label:@"UPS" detail:@"foo" identifier:@"123"];
    STPShippingMethod *method2 = [[STPShippingMethod alloc] initWithAmount:200 currency:@"usd" label:@"FedEx" detail:@"bar" identifier:@"456"];
    STPShippingMethod *method3 = [[STPShippingMethod alloc] initWithAmount:200 currency:@"usd" label:@"Pigeon" detail:@"baz" identifier:@"789"];
    NSArray<STPShippingMethod *>*methods = @[method1, method2];

    NSArray<PKShippingMethod *>*pkMethods = [STPShippingMethod pkShippingMethods:methods selectedMethod:method3];
    XCTAssertEqual((int)[pkMethods count], 2);
    XCTAssertEqualObjects(pkMethods[0].identifier, @"123");
    XCTAssertEqualObjects(pkMethods[1].identifier, @"456");
}

- (void)testPKShippingMethods_noSelectedMethod {
    STPShippingMethod *method1 = [[STPShippingMethod alloc] initWithAmount:100 currency:@"usd" label:@"UPS" detail:@"foo" identifier:@"123"];
    STPShippingMethod *method2 = [[STPShippingMethod alloc] initWithAmount:200 currency:@"usd" label:@"FedEx" detail:@"bar" identifier:@"456"];
    NSArray<STPShippingMethod *>*methods = @[method1, method2];

    NSArray<PKShippingMethod *>*pkMethods = [STPShippingMethod pkShippingMethods:methods selectedMethod:nil];
    XCTAssertEqual((int)[pkMethods count], 2);
    XCTAssertEqualObjects(pkMethods[0].identifier, @"123");
    XCTAssertEqualObjects(pkMethods[1].identifier, @"456");
}

- (void)testPKShippingMethods_noMethods {
    STPShippingMethod *method = [[STPShippingMethod alloc] initWithAmount:100 currency:@"usd" label:@"UPS" detail:@"foo" identifier:@"123"];
    NSArray<PKShippingMethod *>*pkMethods1 = [STPShippingMethod pkShippingMethods:@[] selectedMethod:method];
    XCTAssertEqualObjects(pkMethods1, @[]);

    NSArray<PKShippingMethod *>*pkMethods2 = [STPShippingMethod pkShippingMethods:nil selectedMethod:method];
    XCTAssertEqualObjects(pkMethods2, @[]);
}

@end
