//
//  STPPaymentMethodSofortTests.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodSofort.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodSofortTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *sofortJSON;

@end

@implementation STPPaymentMethodSofortTests

- (void)_retrieveSofortJSON:(void (^)(NSDictionary *))completion {
    if (self.sofortJSON) {
        completion(self.sofortJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1HDdfSFY0qyl6XeWjk7ogYVV_secret_5ikjoct7F271A4Bp6t7HkHwUo"
                                               expand:@[@"payment_method"] completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_sofortJSON = paymentIntent.paymentMethod.sofort.allResponseFields;
            completion(self.sofortJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *jsonExpectation = [[XCTestExpectation alloc] initWithDescription:@"Fetch Sofort JSON"];
    [self _retrieveSofortJSON:^(NSDictionary *json) {
        STPPaymentMethodSofort *sofort = [STPPaymentMethodSofort decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(sofort, @"Failed to decode JSON");
        [jsonExpectation fulfill];
    }];
    [self waitForExpectations:@[jsonExpectation] timeout:STPTestingNetworkRequestTimeout];
}

@end
