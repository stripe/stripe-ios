//
//  STPPaymentMethodParamsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodParams.h"

@interface STPPaymentMethodParamsTest : XCTestCase

@end

@implementation STPPaymentMethodParamsTest

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPPaymentMethodParams rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPPaymentMethodParams *params = [STPPaymentMethodParams new];
    
    NSDictionary *mapping = [STPPaymentMethodParams propertyNamesToFormFieldNamesMapping];
    
    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([params respondsToSelector:NSSelectorFromString(propertyName)]);
    }
    
    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }
    
    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
