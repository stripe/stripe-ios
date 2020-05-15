//
//  STPPaymentMethodBancontactTests.m
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodBancontact.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodBancontactTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *bancontactJSON;

@end

@implementation STPPaymentMethodBancontactTests

- (void)_retrieveBancontactJSON:(void (^)(NSDictionary *))completion {
    if (self.bancontactJSON) {
        completion(self.bancontactJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
        [client retrievePaymentIntentWithClientSecret:@"pi_1GdPnbFY0qyl6XeW8Ezvxe87_secret_Fxi2EZBQ0nInHumvvezcTRWF4"
                                               expand:@[@"payment_method"]
                                           completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_bancontactJSON = paymentIntent.paymentMethod.bancontact.allResponseFields;
            completion(self.bancontactJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retrieve payment intent"];
    [self _retrieveBancontactJSON:^(NSDictionary *json) {
        STPPaymentMethodBancontact *bancontact = [STPPaymentMethodBancontact decodedObjectFromAPIResponse:json];
        XCTAssertNotNil(bancontact, @"Failed to decode JSON");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
