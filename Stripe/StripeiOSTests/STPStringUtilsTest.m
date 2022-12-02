//
//  STPStringUtilsTest.m
//  Stripe
//
//  Created by Brian Dorfman on 9/8/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface STPStringUtilsTest : XCTestCase

@end

@implementation STPStringUtilsTest

- (void)testExpirationDateStrings {
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"12/1995"], @"12/95");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"12 / 1995"], @"12 / 95");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"12 /1995"], @"12 /95");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"1295"], @"1295");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"12/95"], @"12/95");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"08/2001"], @"08/01");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@" 08/a 2001"], @" 08/a 2001");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"20/2022"], @"20/22");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"20/202222"], @"20/22");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@""], @"");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@" "], @" ");
    XCTAssertEqualObjects([STPStringUtils expirationDateStringFromString:@"12/"], @"12/");
}



@end
