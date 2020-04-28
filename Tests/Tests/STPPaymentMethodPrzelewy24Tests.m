//
//  STPPaymentMethodPrzelewy24Tests.m
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodPrzelewy24.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodPrzelewy24Tests : XCTestCase

@property (nonatomic, readonly) NSDictionary *przelewy24JSON;

@end

@implementation STPPaymentMethodPrzelewy24Tests

- (void)_retrievePrzelewy24JSON:(void (^)(NSDictionary *))completion {
    if (self.przelewy24JSON) {
        completion(self.przelewy24JSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1GciHFFY0qyl6XeWp9RdhmFF_secret_rFeERcidL1O5o1lwQUcIjLEZz"
                                               expand:@[@"payment_method"]
                                           completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_przelewy24JSON = paymentIntent.paymentMethod.przelewy24.allResponseFields;
            completion(self.przelewy24JSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve payment intent"];
    [self _retrievePrzelewy24JSON:^(NSDictionary *json) {
        STPPaymentMethodPrzelewy24 *przelewy24 = [STPPaymentMethodPrzelewy24 decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(przelewy24, @"Failed to decode JSON");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
