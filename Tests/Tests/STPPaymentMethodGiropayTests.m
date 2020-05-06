//
//  STPPaymentMethodGiropayTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodGiropay.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodGiropayTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *giropayJSON;

@end

@implementation STPPaymentMethodGiropayTests

- (void)_retrieveGiropayDebitJSON:(void (^)(NSDictionary *))completion {
    if (self.giropayJSON) {
        completion(self.giropayJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1GfsdtFY0qyl6XeWLnepIXCI_secret_bLJRSeSY7fBjDXnwh9BUKilMW"
                                               expand:@[@"payment_method"] completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_giropayJSON = paymentIntent.paymentMethod.giropay.allResponseFields;
            completion(self.giropayJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *jsonExpectation = [[XCTestExpectation alloc] initWithDescription:@"Fetch Giropay JSON"];
    [self _retrieveGiropayDebitJSON:^(NSDictionary *json) {
        STPPaymentMethodGiropay *giropay = [STPPaymentMethodGiropay decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(giropay, @"Failed to decode JSON");
        [jsonExpectation fulfill];
    }];
    [self waitForExpectations:@[jsonExpectation] timeout:STPTestingNetworkRequestTimeout];
}

@end
