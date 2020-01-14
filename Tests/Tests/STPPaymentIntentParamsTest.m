//
//  STPPaymentIntentParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentIntentParams.h"
#import "STPPaymentIntentParams+Utilities.h"

#import "STPConfirmPaymentMethodOptions.h"
#import "STPMandateCustomerAcceptanceParams.h"
#import "STPMandateDataParams.h"
#import "STPMandateOnlineParams+Private.h"
#import "STPPaymentMethodParams.h"

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
        XCTAssertNil(params.mandateData);
        XCTAssertNil(params.mandate);
        XCTAssertNil(params.paymentMethodOptions);
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

- (void)testDefaultMandateData {
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] init];

    // no configuration should have no mandateData
    XCTAssertNil(params.mandateData);

    params.paymentMethodParams = [[STPPaymentMethodParams alloc] init];

    params.paymentMethodParams.rawTypeString = @"card";
    // card type should have no default mandateData
    XCTAssertNil(params.mandateData);

    params.paymentMethodParams.rawTypeString = @"sepa_debit";
    // SEPA Debit type should have mandateData
    XCTAssertNotNil(params.mandateData);
    XCTAssertEqual(params.mandateData.customerAcceptance.onlineParams.inferFromClient, @YES);

    params.mandate = @"my_mandate";
    // SEPA Debit with a mandate ID should not have default
     XCTAssertNil(params.mandateData);

    params.mandate = nil;
    params.mandateData = [[STPMandateDataParams alloc] init];
    // Default behavior should not override custom setting
    XCTAssertNotNil(params.mandateData);
    XCTAssertNil(params.mandateData.customerAcceptance);
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
    params.mandate = @"test_mandate";
    params.mandateData = [[STPMandateDataParams alloc] init];
    params.paymentMethodOptions = [[STPConfirmPaymentMethodOptions alloc] init];
    params.additionalAPIParameters = @{@"other_param" : @"other_value"};

    STPPaymentIntentParams *paramsCopy = [params copy];
    XCTAssertEqualObjects(params.clientSecret, paramsCopy.clientSecret);
    XCTAssertEqualObjects(params.paymentMethodId, paramsCopy.paymentMethodId);

    // assert equal, not equal objects, because this is a shallow copy
    XCTAssertEqual(params.paymentMethodParams, paramsCopy.paymentMethodParams);
    XCTAssertEqual(params.mandateData, paramsCopy.mandateData);

    XCTAssertEqualObjects(params.savePaymentMethod, paramsCopy.savePaymentMethod);
    XCTAssertEqualObjects(params.returnURL, paramsCopy.returnURL);
    XCTAssertEqualObjects(params.useStripeSDK, paramsCopy.useStripeSDK);
    XCTAssertEqualObjects(params.mandate, paramsCopy.mandate);
    XCTAssertEqualObjects(params.paymentMethodOptions, paramsCopy.paymentMethodOptions);
    XCTAssertEqualObjects(params.additionalAPIParameters, paramsCopy.additionalAPIParameters);

}

- (void)testClientSecretValidation {
    XCTAssertFalse([STPPaymentIntentParams isClientSecretValid:@"pi_12345"], @"'pi_12345' is not a valid client secret.");
    XCTAssertFalse([STPPaymentIntentParams isClientSecretValid:@"pi_12345_secret_"], @"'pi_12345_secret_' is not a valid client secret.");
    XCTAssertFalse([STPPaymentIntentParams isClientSecretValid:@"pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9"], @"'pi_a1b2c3_secret_x7y8z9pi_a1b2c3_secret_x7y8z9' is not a valid client secret.");
    XCTAssertFalse([STPPaymentIntentParams isClientSecretValid:@"seti_a1b2c3_secret_x7y8z9"], @"'seti_a1b2c3_secret_x7y8z9' is not a valid client secret.");


    XCTAssertTrue([STPPaymentIntentParams isClientSecretValid:@"pi_a1b2c3_secret_x7y8z9"], @"'pi_a1b2c3_secret_x7y8z9' is a valid client secret.");
    XCTAssertTrue([STPPaymentIntentParams isClientSecretValid:@"pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA"], @"'pi_1CkiBMLENEVhOs7YMtUehLau_secret_s4O8SDh7s6spSmHDw1VaYPGZA' is a valid client secret.");
}

@end
