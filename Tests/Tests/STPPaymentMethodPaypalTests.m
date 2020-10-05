//
//  STPPaymentMethodPaypalTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodPaypal.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodPaypalTests : XCTestCase

@property (nonatomic) NSDictionary *paypalJSON;

@end

@implementation STPPaymentMethodPaypalTests

- (void)_retrievePaypalJSON:(void (^)(NSDictionary *))completion {
    if (self.paypalJSON) {
        completion(self.paypalJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1HZhbdFY0qyl6XeW32rAcdaW_secret_XlsNvqKb4WGkrFuoRdmlichQ4"
                                               expand:@[@"payment_method"]
                                           completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_paypalJSON = paymentIntent.paymentMethod.paypal.allResponseFields;
            completion(self.paypalJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve payment intent"];
    [self _retrievePaypalJSON:^(NSDictionary *json) {
        STPPaymentMethodPaypal *paypal = [STPPaymentMethodPaypal decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(paypal, @"Failed to decode JSON");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
