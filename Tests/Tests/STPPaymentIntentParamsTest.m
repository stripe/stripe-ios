//
//  STPPaymentIntentParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentIntentParams.h"

@interface STPPaymentIntentParamsTest : XCTestCase

@end

@implementation STPPaymentIntentParamsTest

- (void)testInit {
    for (STPPaymentIntentParams *params in @[[[STPPaymentIntentParams alloc] initWithClientSecret:@"secret"],
                                             [[STPPaymentIntentParams alloc] init],
                                             [STPPaymentIntentParams new],
                                             ]) {
        XCTAssertNotNil(params);
        XCTAssertNotNil(params.clientSecret);
        XCTAssertNotNil(params.additionalAPIParameters);
        XCTAssertEqual(params.additionalAPIParameters.count, 0UL);

        XCTAssertNil(params.stripeId, @"invalid secrets, no stripeId");
        XCTAssertNil(params.sourceParams);
        XCTAssertNil(params.sourceId);
        XCTAssertNil(params.receiptEmail);
        XCTAssertNil(params.saveSourceToCustomer);
        XCTAssertNil(params.returnUrl);
    }
}

// FIXME: test description

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPPaymentIntentParams rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPPaymentIntentParams *params = [STPPaymentIntentParams new];

    NSDictionary *mapping = [STPPaymentIntentParams propertyNamesToFormFieldNamesMapping];

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
