//
//  STPPaymentMethodAUBECSDebitTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodAUBECSDebit.h"
#import "STPTestingAPIClient.h"

static NSString * kAUBECSDebitPaymentIntentClientSecret = @"pi_1GaRLjF7QokQdxByYgFPQEi0_secret_z76otRQH2jjOIEQYsA9vxhuKn";


@interface STPPaymentMethodAUBECSDebitTests : XCTestCase

@property (nonatomic, readonly) NSDictionary *auBECSDebitJSON;

@end

@implementation STPPaymentMethodAUBECSDebitTests

- (void)_retrieveAUBECSDebitJSON:(void (^)(NSDictionary *))completion {
    if (self.auBECSDebitJSON) {
        completion(self.auBECSDebitJSON);
    } else {
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingAUPublishableKey];
        [client retrievePaymentIntentWithClientSecret:kAUBECSDebitPaymentIntentClientSecret
                                               expand:@[@"payment_method"] completion:^(STPPaymentIntent * _Nullable paymentIntent, __unused NSError * _Nullable error) {
            self->_auBECSDebitJSON = paymentIntent.paymentMethod.auBECSDebit.allResponseFields;
            completion(self.auBECSDebitJSON);
        }];
    }
}

- (void)testCorrectParsing {
    XCTestExpectation *retrieveJSON = [[XCTestExpectation alloc] initWithDescription:@"Retrieve JSON"];
    [self _retrieveAUBECSDebitJSON:^(NSDictionary *json) {
         STPPaymentMethodAUBECSDebit *auBECSDebit = [STPPaymentMethodAUBECSDebit decodedObjectFromAPIResponse:json];
           XCTAssertNotNil(auBECSDebit, @"Failed to decode JSON");
        [retrieveJSON fulfill];
    }];
    [self waitForExpectations:@[retrieveJSON] timeout:STPTestingNetworkRequestTimeout];
}

- (void)testFailWithoutRequired {
    XCTestExpectation *retrieveJSON = [[XCTestExpectation alloc] initWithDescription:@"Retrieve JSON"];
    [self _retrieveAUBECSDebitJSON:^(NSDictionary *json) {
        NSMutableDictionary *auBECSDebitJSON = [json mutableCopy];
        [auBECSDebitJSON setValue:nil forKey:@"bsb_number"];
        XCTAssertNil([STPPaymentMethodAUBECSDebit decodedObjectFromAPIResponse:auBECSDebitJSON], @"Should not intialize with missing `bsb_number`");
        [retrieveJSON fulfill];
    }];
    [self waitForExpectations:@[retrieveJSON] timeout:STPTestingNetworkRequestTimeout];

    retrieveJSON = [[XCTestExpectation alloc] initWithDescription:@"Retrieve JSON"];
    [self _retrieveAUBECSDebitJSON:^(NSDictionary *json) {
        NSMutableDictionary *auBECSDebitJSON = [json mutableCopy];
        [auBECSDebitJSON setValue:nil forKey:@"last4"];
        XCTAssertNil([STPPaymentMethodAUBECSDebit decodedObjectFromAPIResponse:auBECSDebitJSON], @"Should not intialize with missing `last4`");
        [retrieveJSON fulfill];
    }];
    [self waitForExpectations:@[retrieveJSON] timeout:STPTestingNetworkRequestTimeout];

    retrieveJSON = [[XCTestExpectation alloc] initWithDescription:@"Retrieve JSON"];
    [self _retrieveAUBECSDebitJSON:^(NSDictionary *json) {
        NSMutableDictionary *auBECSDebitJSON = [json mutableCopy];
        [auBECSDebitJSON setValue:nil forKey:@"fingerprint"];
        XCTAssertNil([STPPaymentMethodAUBECSDebit decodedObjectFromAPIResponse:auBECSDebitJSON], @"Should not intialize with missing `fingerprint`");
        [retrieveJSON fulfill];
    }];
    [self waitForExpectations:@[retrieveJSON] timeout:STPTestingNetworkRequestTimeout];
}

@end
