//
//  STPSetupIntentConfirmParamsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPSetupIntentConfirmParams.h"

#import "STPPaymentMethodParams.h"

@interface STPSetupIntentConfirmParamsTest : XCTestCase

@end

@implementation STPSetupIntentConfirmParamsTest

- (void)testInit {
    for (STPSetupIntentConfirmParams *params in @[[[STPSetupIntentConfirmParams alloc] initWithClientSecret:@"secret"],
                                             [[STPSetupIntentConfirmParams alloc] init],
                                             [STPSetupIntentConfirmParams new],
                                             ]) {
        XCTAssertNotNil(params);
        XCTAssertNotNil(params.clientSecret);
        XCTAssertNotNil(params.additionalAPIParameters);
        XCTAssertEqual(params.additionalAPIParameters.count, 0UL);
        XCTAssertNil(params.paymentMethodID);
        XCTAssertNil(params.returnURL);
        XCTAssertNil(params.useStripeSDK);
    }
}

- (void)testDescription {
    STPSetupIntentConfirmParams *params = [[STPSetupIntentConfirmParams alloc] init];
    XCTAssertNotNil(params.description);
}

#pragma mark STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertNil([STPSetupIntentConfirmParams rootObjectName]);
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPSetupIntentConfirmParams *params = [STPSetupIntentConfirmParams new];

    NSDictionary *mapping = [STPSetupIntentConfirmParams propertyNamesToFormFieldNamesMapping];

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

- (void)testCopy {
    STPSetupIntentConfirmParams *params = [[STPSetupIntentConfirmParams alloc] initWithClientSecret:@"test_client_secret"];
    params.paymentMethodParams = [[STPPaymentMethodParams alloc] init];
    params.paymentMethodID = @"test_payment_method_id";
    params.returnURL = @"fake://testing_only";
    params.useStripeSDK = @YES;
    params.additionalAPIParameters = @{@"other_param" : @"other_value"};

    STPSetupIntentConfirmParams *paramsCopy = [params copy];
    XCTAssertEqualObjects(params.clientSecret, paramsCopy.clientSecret);
    XCTAssertEqualObjects(params.paymentMethodID, paramsCopy.paymentMethodID);

    // assert equal, not equal objects, because this is a shallow copy
    XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams);

    XCTAssertEqualObjects(params.returnURL, paramsCopy.returnURL);
    XCTAssertEqualObjects(params.useStripeSDK, paramsCopy.useStripeSDK);
    XCTAssertEqualObjects(params.additionalAPIParameters, paramsCopy.additionalAPIParameters);


}

@end
