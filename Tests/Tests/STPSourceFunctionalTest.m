//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"

@interface STPSourceFunctionalTest : XCTestCase

@end

@implementation STPSourceFunctionalTest

- (void)testCreateSource_sofort {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"sofort";
    params.amount = @1099;
    params.currency = @"eur";
    params.redirect = @{@"return_url": @"https://shop.foo.com/crtA6B28E1"};
    params.metadata = @{@"foo": @"bar"};
    params.additionalAPIParameters = @{
                                       @"sofort": @{
                                               @"country": @"DE",
                                               @"statement_descriptor": @"ORDER AT11990"
                                               }
                                       };

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, params.type);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.redirect[@"return_url"], params.redirect[@"return_url"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);
        XCTAssertEqualObjects(source.allResponseFields[@"sofort"][@"country"], @"DE");

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSource_bitcoin {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"bitcoin";
    params.amount = @1000;
    params.currency = @"usd";
    params.owner = @{
                     @"email": @"payinguser+fill_now@example.com",
                     };
    params.metadata = @{@"foo": @"bar"};

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Source creation"];
    [client createSourceWithParams:params completion:^(STPSource *source, NSError * error) {
        XCTAssertNil(error);
        XCTAssertNotNil(source);
        XCTAssertEqualObjects(source.type, params.type);
        XCTAssertEqualObjects(source.amount, params.amount);
        XCTAssertEqualObjects(source.currency, params.currency);
        XCTAssertEqualObjects(source.owner[@"email"], params.owner[@"email"]);
        XCTAssertEqualObjects(source.metadata, params.metadata);

        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
