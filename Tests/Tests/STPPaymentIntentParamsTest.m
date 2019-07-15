//
//  STPPaymentIntentParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentIntentParams.h"
#import "STPPaymentmethodParams.h"

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertNil(params.saveSourceToCustomer);
#pragma clang diagnostic pop
        XCTAssertNil(params.savePaymentMethod);
        XCTAssertNil(params.returnURL);
        XCTAssertNil(params.setupFutureUsage);
        XCTAssertNil(params.useStripeSDK);
    }
}

- (void)testDescription {
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] init];
    XCTAssertNotNil(params.description);
}

#pragma mark Deprecated Property

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (void)testReturnURLRenaming {
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] init];

    XCTAssertNil(params.returnURL);
    XCTAssertNil(params.returnUrl);

    params.returnURL = @"set via new name";
    XCTAssertEqualObjects(params.returnUrl, @"set via new name");

    params.returnUrl = @"set via old name";
    XCTAssertEqualObjects(params.returnURL, @"set via old name");
}

- (void)testSaveSourceToCustomerRenaming {
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] init];
    
    XCTAssertNil(params.saveSourceToCustomer);
    XCTAssertNil(params.savePaymentMethod);
    
    params.savePaymentMethod = @NO;
    XCTAssertEqualObjects(params.saveSourceToCustomer, @NO);
    
    params.saveSourceToCustomer = @YES;
    XCTAssertEqualObjects(params.savePaymentMethod, @YES);
}

#pragma clang diagnostic pop

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

- (void)testCopy {
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:@"test_client_secret"];
    params.paymentMethodParams = [[STPPaymentMethodParams alloc] init];
    params.paymentMethodId = @"test_payment_method_id";
    params.savePaymentMethod = @YES;
    params.returnURL = @"fake://testing_only";
    params.setupFutureUsage = @(1);
    params.useStripeSDK = @YES;
    params.additionalAPIParameters = @{@"other_param" : @"other_value"};

    STPPaymentIntentParams *paramsCopy = [params copy];
    XCTAssertEqualObjects(params.clientSecret, paramsCopy.clientSecret);
    XCTAssertEqualObjects(params.paymentMethodId, paramsCopy.paymentMethodId);

    // assert equal, not equal objects, because this is a shallow copy
    XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams);

    XCTAssertEqualObjects(params.savePaymentMethod, paramsCopy.savePaymentMethod);
    XCTAssertEqualObjects(params.returnURL, paramsCopy.returnURL);
    XCTAssertEqualObjects(params.useStripeSDK, paramsCopy.useStripeSDK);
    XCTAssertEqualObjects(params.additionalAPIParameters, paramsCopy.additionalAPIParameters);


}

@end
