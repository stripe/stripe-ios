//
//  STPPaymentMethodEPSTest.m
//  StripeiOS Tests
//
//  Created by Shengwei Wu on 5/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodEPS.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodEPSTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *epsJSON;

@end

@implementation STPPaymentMethodEPSTests

- (void)_retrieveEPSJSON:(void (^)(NSDictionary *))completion {
    if (self.epsJSON) {
        completion(self.epsJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1Gj0rqFY0qyl6XeWrug30CPz_secret_tKyf8QOKtiIrE3NSEkWCkBbyy"
                                               expand:@[@"payment_method"] completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_epsJSON = paymentIntent.paymentMethod.eps.allResponseFields;
            completion(self.epsJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *jsonExpectation = [[XCTestExpectation alloc] initWithDescription:@"Fetch EPS JSON"];
    [self _retrieveEPSJSON:^(NSDictionary *json) {
        STPPaymentMethodEPS *eps = [STPPaymentMethodEPS decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(eps, @"Failed to decode JSON");
        [jsonExpectation fulfill];
    }];
    [self waitForExpectations:@[jsonExpectation] timeout:STPTestingNetworkRequestTimeout];
}

@end
