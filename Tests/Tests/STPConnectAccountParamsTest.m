//
//  STPConnectAccountParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/10/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPConnectAccountParams.h"
#import "STPLegalEntityParams.h"

@interface STPConnectAccountParamsTest : XCTestCase
@end

@implementation STPConnectAccountParamsTest

#pragma mark - STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPConnectAccountParams rootObjectName], @"account");
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPConnectAccountParams *accountParams = [[STPConnectAccountParams alloc] initWithLegalEntity:[STPLegalEntityParams new]];

    NSDictionary *mapping = [STPConnectAccountParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([accountParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
