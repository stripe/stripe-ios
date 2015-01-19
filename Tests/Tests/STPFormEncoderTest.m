//
//  STPFormEncoderTest.m
//  Stripe Tests
//
//  Created by Jack Flintermann on 1/8/15.
//
//

#import <XCTest/XCTest.h>
#import "STPFormEncoder.h"

@interface STPFormEncoderTest : XCTestCase

@end

@implementation STPFormEncoderTest

- (void)testStringByReplacingSnakeCaseWithCamelCase {
    NSString *camelCase = [STPFormEncoder stringByReplacingSnakeCaseWithCamelCase:@"test_1_2_34_test"];
    XCTAssertEqualObjects(@"test1234Test", camelCase);
}

@end
