//
//  NSString+EmptyCheckingTests.m
//  Stripe3DS2Tests
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+EmptyChecking.h"

@interface NSString_EmptyCheckingTests : XCTestCase

@end

@implementation NSString_EmptyCheckingTests

- (void)testStringIsEmpty {
    XCTAssertTrue([NSString _stds_isStringEmpty:@""]);
    XCTAssertTrue([NSString _stds_isStringEmpty:@" "]);
    XCTAssertTrue([NSString _stds_isStringEmpty:@"\n"]);
    XCTAssertTrue([NSString _stds_isStringEmpty:@"\t"]);
}

- (void)testStringIsNotEmpty {
    XCTAssertFalse([NSString _stds_isStringEmpty:@"Hello"]);
    XCTAssertFalse([NSString _stds_isStringEmpty:@","]);
    XCTAssertFalse([NSString _stds_isStringEmpty:@"\\n"]);
}

@end
