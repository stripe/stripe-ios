//
//  STPPaymentMethodOXXOTests.m
//  StripeiOS Tests
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodOXXOTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *oxxoJSON;

@end

@implementation STPPaymentMethodOXXOTests

- (void)_retrieveOXXOJSON:(void (^)(NSDictionary *))completion {
    if (self.oxxoJSON) {
        completion(self.oxxoJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingMEXPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1GvAdyHNG4o8pO5l0dr078gf_secret_h0tJE5mSX9BPEkmpKSh93jBXi"
                                               expand:@[@"payment_method"]
                                           completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_oxxoJSON = paymentIntent.paymentMethod.oxxo.allResponseFields;
            completion(self.oxxoJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve payment intent"];
    [self _retrieveOXXOJSON:^(NSDictionary *json) {
        STPPaymentMethodOXXO *oxxo = [STPPaymentMethodOXXO decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(oxxo, @"Failed to decode JSON");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
