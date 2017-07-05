//
//  STPAPIRequestTest.m
//  Stripe
//
//  Created by Ben Guo on 5/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "STPAPIRequest.h"
#import "STPTestUtils.h"

@interface STPAPIRequestTest : XCTestCase

@end

@implementation STPAPIRequestTest

- (void)testParseResponseWithMultipleDeserializers {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = [STPTestUtils jsonNamed:@"CardSource"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[[STPCard new], [STPSource new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertEqualObjects(object, [STPSource decodedObjectFromAPIResponse:json]);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertNil(error);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithMultipleDeserializersNoMatchingObject {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = [STPTestUtils jsonNamed:@"CardSource"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[[STPFile new], [STPBankAccount new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, [NSError stp_genericFailedToParseResponseError]);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithOneDeserializer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = [STPTestUtils jsonNamed:@"Customer"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[[STPCustomer new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertEqualObjects(((STPCustomer *)object).stripeID, [STPCustomer decodedObjectFromAPIResponse:json].stripeID);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertNil(error);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithNoDeserializers {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = [STPTestUtils jsonNamed:@"EphemeralKey"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, [NSError stp_genericFailedToParseResponseError]);
                          [expectation fulfill];
                      }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithConnectionError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = @{};
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
    NSArray *deserializers = @[[STPCard new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, errorParameter);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithReturnedError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = @{
                           @"error": @{
                                   @"type": @"invalid_request_error",
                                   @"message": @"Your card number is incorrect.",
                                   @"code": @"incorrect_number",
                                   }
                           };
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[[STPCard new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, [NSError stp_errorFromStripeResponse:json]);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithMissingError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = @{};
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = nil;
    NSArray *deserializers = @[[STPCard new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, [NSError stp_genericFailedToParseResponseError]);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testParseResponseWithResponseObjectAndReturnedError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"parseResponse"];

    NSHTTPURLResponse *httpURLResponse = [[NSHTTPURLResponse alloc] init];
    NSDictionary *json = [STPTestUtils jsonNamed:@"CardSource"];
    NSData *body = [NSJSONSerialization dataWithJSONObject:json options:(NSJSONWritingOptions)kNilOptions error:nil];
    NSError *errorParameter = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    NSArray *deserializers = @[[STPCard new]];

    [STPAPIRequest parseResponse:httpURLResponse
                            body:body
                           error:errorParameter
                   deserializers:deserializers
                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                          XCTAssertNil(object);
                          XCTAssertEqualObjects(response, httpURLResponse);
                          XCTAssertEqualObjects(error, errorParameter);
                          [expectation fulfill];
                      }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
