//
//  STPConnectAccountAddressTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPConnectAccountAddress.h"

@interface STPConnectAccountAddressTest : XCTestCase

@end

@implementation STPConnectAccountAddressTest

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPConnectAccountAddress rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPConnectAccountAddress *address = [STPConnectAccountAddress new];
    
    NSDictionary *mapping = [STPConnectAccountAddress propertyNamesToFormFieldNamesMapping];
    
    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([address respondsToSelector:NSSelectorFromString(propertyName)]);
    }
    
    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }
    
    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
