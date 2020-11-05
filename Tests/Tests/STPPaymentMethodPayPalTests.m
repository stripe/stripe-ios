//
//  STPPaymentMethodPayPalTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodPayPalTests : XCTestCase

@property (nonatomic) NSDictionary *payPalJSON;

@end

@implementation STPPaymentMethodPayPalTests

- (void)_retrievePayPalJSON:(void (^)(NSDictionary *))completion {
    if (self.payPalJSON) {
        completion(self.payPalJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1HcI17FY0qyl6XeWcFAAbZCw_secret_oAZ9OCoeyIg8EPeBEdF96ZJOT"
                                               expand:@[@"payment_method"]
                                           completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_payPalJSON = paymentIntent.lastPaymentError.paymentMethod.payPal.allResponseFields;
            completion(self.payPalJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve payment intent"];
    [self _retrievePayPalJSON:^(NSDictionary *json) {
        STPPaymentMethodPayPal *payPal = [STPPaymentMethodPayPal decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(payPal, @"Failed to decode JSON");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
