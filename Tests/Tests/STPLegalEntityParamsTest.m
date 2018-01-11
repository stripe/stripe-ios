//
//  STPLegalEntityParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/10/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPLegalEntityParams.h"

@interface STPLegalEntityParamsTest : XCTestCase
@end

@implementation STPLegalEntityParamsTest

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPLegalEntityParams rootObjectName], @"legal_entity");
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPLegalEntityParams *entityParams = [STPLegalEntityParams new];

    NSDictionary *mapping = [STPLegalEntityParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([entityParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end


@interface STPPersonParamsTest : XCTestCase
@end

@implementation STPPersonParamsTest

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPPersonParams rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPPersonParams *personParams = [STPPersonParams new];

    NSDictionary *mapping = [STPPersonParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([personParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end


@interface STPVerificationParamsTest : XCTestCase
@end

@implementation STPVerificationParamsTest

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPVerificationParams rootObjectName], @"verification");
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPVerificationParams *verificationParams = [STPVerificationParams new];

    NSDictionary *mapping = [STPVerificationParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([verificationParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end

// this was declared privately in STPLegalEntityParams.m
@interface NSDateComponents (STPFormEncodable) <STPFormEncodable> @end

@interface STPDateComponentsFormEncodableTest : XCTestCase
@end

@implementation STPDateComponentsFormEncodableTest

#pragma mark STPFormEncodable Tests

- (void)testIsFormEncodable {
    XCTAssertTrue([[NSDateComponents class] conformsToProtocol:@protocol(STPFormEncodable)]);
}

- (void)testRootObjectName {
    XCTAssertNil([NSDateComponents rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    NSDateComponents *components = [NSDateComponents new];

    NSDictionary *mapping = [NSDateComponents propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([components respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
