//
//  STPConnectAccountParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/10/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPConnectAccountParams.h"

@interface STPConnectAccountParams (Testing)
+ (NSString *)stringFromBusinessType:(STPConnectAccountBusinessType)businessType;
@end

@interface STPConnectAccountParamsTest : XCTestCase
@end

@implementation STPConnectAccountParamsTest

#pragma mark - STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPConnectAccountParams rootObjectName], @"account");
}

- (void)testBusinessType {
    XCTAssertEqual([[STPConnectAccountParams alloc] initWithIndividual:@{}].businessType, STPConnectAccountBusinessTypeIndividual);
    XCTAssertEqual([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:YES individual:@{}].businessType, STPConnectAccountBusinessTypeIndividual);

    XCTAssertEqual([[STPConnectAccountParams alloc] initWithCompany:@{}].businessType, STPConnectAccountBusinessTypeCompany);
    XCTAssertEqual([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:YES company:@{}].businessType, STPConnectAccountBusinessTypeCompany);
}

- (void)testBusinessTypeString {
    XCTAssertEqualObjects(@"individual", [STPConnectAccountParams stringFromBusinessType:STPConnectAccountBusinessTypeIndividual]);
    XCTAssertEqualObjects(@"company", [STPConnectAccountParams stringFromBusinessType:STPConnectAccountBusinessTypeCompany]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPConnectAccountParams *accountParams = [[STPConnectAccountParams alloc] initWithIndividual:@{}];

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
