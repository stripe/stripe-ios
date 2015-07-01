//
//  PTKCardCVCTest.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 2/6/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCardCVCTest.h"
#import "PTKCardCVC.h"
#define CCVC(string) [PTKCardCVC cardCVCWithString:string]

@implementation PTKCardCVCTest

- (void) testStripsNonIntegers
{
    
    XCTAssertEqualObjects([CCVC(@"123") string], @"123", @"Strips non integers");
    XCTAssertEqualObjects([CCVC(@"12d3") string], @"123", @"Strips non integers");
}

- (void) testIsValid
{
    XCTAssertTrue([CCVC(@"123") isValid], @"Test is valid");
    XCTAssertTrue(![CCVC(@"12334") isValid], @"Test is valid");
    XCTAssertTrue(![CCVC(@"34") isValid], @"Test is valid");
}

- (void) testIsPartiallyValid
{
    XCTAssertTrue([CCVC(@"123") isPartiallyValid], @"Test is valid");
    XCTAssertTrue(![CCVC(@"12334") isPartiallyValid], @"Test is valid");
    XCTAssertTrue([CCVC(@"1234") isPartiallyValid], @"Test is valid");
    XCTAssertTrue([CCVC(@"34")isPartiallyValid], @"Test is valid");
}

- (void) testIsPartiallyValidWithType
{
    XCTAssertTrue([CCVC(@"123") isPartiallyValidWithType:PTKCardTypeVisa], @"Test is valid");
    XCTAssertTrue(![CCVC(@"1234") isPartiallyValidWithType:PTKCardTypeVisa], @"Test is valid");

    XCTAssertTrue([CCVC(@"123") isPartiallyValidWithType:PTKCardTypeAmex], @"Test is valid");
    XCTAssertTrue([CCVC(@"1234") isPartiallyValidWithType:PTKCardTypeAmex], @"Test is valid");
}

@end
