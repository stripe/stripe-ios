//
//  STPAPIRequestTest.m
//  Stripe
//
//  Created by Ben Guo on 5/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>

#import "STPAPIRequest.h"

#import "NSError+Stripe.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "STPTestUtils.h"

@interface STPAPIRequest ()

+ (void)parseResponse:(NSURLResponse *)response
                 body:(NSData *)body
                error:(NSError *)error
        deserializers:(NSArray<id<STPAPIResponseDecodable>>*)deserializers
           completion:(STPAPIResponseBlock)completion;

@end

@interface STPAPIRequestTest : XCTestCase

@end

@implementation STPAPIRequestTest

- (void)testPostWithAPIClient {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];

    // Setup mocks
    NSURLSessionDataTask *dataTaskMock = OCMClassMock([NSURLSessionDataTask class]);

    NSURLSession *urlSessionMock = OCMClassMock([NSURLSession class]);
    OCMStub([urlSessionMock dataTaskWithRequest:[OCMArg any]
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
        completionHandler((NSData *)@"body", (NSURLResponse *)@"response", (NSError *)@"error");
        return YES;
    }]]).andReturn(dataTaskMock);

    STPAPIClient *apiClientMock = OCMClassMock([STPAPIClient class]);
    OCMStub([apiClientMock apiURL]).andReturn([NSURL URLWithString:@"https://api.stripe.com"]);
    OCMStub([apiClientMock urlSession]).andReturn(urlSessionMock);
    OCMStub([apiClientMock configuredRequestForURL:[OCMArg isKindOfClass:[NSURL class]]]).andDo(^(NSInvocation *invocation)
                                                                                                {
                                                                                                    NSURL *urlArg;
                                                                                                    [invocation getArgument:&urlArg atIndex:2];
                                                                                                    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlArg];
                                                                                                    [invocation setReturnValue:&request];
                                                                                                    [invocation retainArguments];
                                                                                                });

    id apiRequestMock = OCMClassMock([STPAPIRequest class]);
    OCMStub([apiRequestMock parseResponse:[OCMArg any]
                                     body:[OCMArg any]
                                    error:[OCMArg any]
                            deserializers:[OCMArg any]
                               completion:[OCMArg checkWithBlock:^BOOL(STPAPIResponseBlock completion) {
        completion((STPCard *)@"card", (NSHTTPURLResponse *)@"httpURLResponse", (NSError *)@"error");
        return YES;
    }]]);

    // Perform request
    NSString *endpoint = @"endpoint";
    NSDictionary *parameters = @{@"key": @"value"};
    STPCard *deserializer = [STPCard new];

    NSURLSessionDataTask *task = [STPAPIRequest postWithAPIClient:apiClientMock
                                                         endpoint:endpoint
                                                       parameters:parameters
                                                     deserializer:deserializer
                                                       completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                                                           XCTAssertEqualObjects(object, (STPCard *)@"card");
                                                           XCTAssertEqualObjects(response, (NSHTTPURLResponse *)@"httpURLResponse");
                                                           XCTAssertEqualObjects(error, (NSError *)@"error");
                                                           [expectation fulfill];
                                                       }];
    XCTAssertEqualObjects(task, dataTaskMock);

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertNil(error);

        // Verify mocks
        OCMVerify([dataTaskMock resume]);

        OCMVerify([urlSessionMock dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            XCTAssertEqualObjects(request.URL, [NSURL URLWithString:@"https://api.stripe.com/endpoint"]);
            XCTAssertEqualObjects(request.HTTPMethod, @"POST");
            XCTAssertEqualObjects([[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], @"key=value");
            return YES;
        }] completionHandler:[OCMArg any]]);

        OCMVerify([apiRequestMock parseResponse:[OCMArg isEqual:@"response"]
                                           body:[OCMArg isEqual:@"body"]
                                          error:[OCMArg isEqual:@"error"]
                                  deserializers:[OCMArg checkWithBlock:^BOOL(NSArray *deserializers) {
            XCTAssert([deserializers.firstObject isKindOfClass:[STPCard class]]);
            XCTAssertEqual(deserializers.count, (NSUInteger)1);
            return YES;
        }] completion:[OCMArg any]]);
    }];
}

- (void)testGetWithAPIClient {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];

    // Setup mocks
    NSURLSessionDataTask *dataTaskMock = OCMClassMock([NSURLSessionDataTask class]);

    NSURLSession *urlSessionMock = OCMClassMock([NSURLSession class]);
    OCMStub([urlSessionMock dataTaskWithRequest:[OCMArg any]
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
        completionHandler((NSData *)@"body", (NSURLResponse *)@"response", (NSError *)@"error");
        return YES;
    }]]).andReturn(dataTaskMock);

    STPAPIClient *apiClientMock = OCMClassMock([STPAPIClient class]);
    OCMStub([apiClientMock apiURL]).andReturn([NSURL URLWithString:@"https://api.stripe.com"]);
    OCMStub([apiClientMock urlSession]).andReturn(urlSessionMock);
    OCMStub([apiClientMock configuredRequestForURL:[OCMArg isKindOfClass:[NSURL class]]]).andDo(^(NSInvocation *invocation)
                                                                                                {
                                                                                                    NSURL *urlArg;
                                                                                                    [invocation getArgument:&urlArg atIndex:2];
                                                                                                    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlArg];
                                                                                                    [invocation setReturnValue:&request];
                                                                                                    [invocation retainArguments];
                                                                                                });

    id apiRequestMock = OCMClassMock([STPAPIRequest class]);
    OCMStub([apiRequestMock parseResponse:[OCMArg any]
                                     body:[OCMArg any]
                                    error:[OCMArg any]
                            deserializers:[OCMArg any]
                               completion:[OCMArg checkWithBlock:^BOOL(STPAPIResponseBlock completion) {
        completion((STPCard *)@"card", (NSHTTPURLResponse *)@"httpURLResponse", (NSError *)@"error");
        return YES;
    }]]);

    // Perform request
    NSString *endpoint = @"endpoint";
    NSDictionary *parameters = @{@"key": @"value"};
    STPCard *deserializer = [STPCard new];

    NSURLSessionDataTask *task = [STPAPIRequest getWithAPIClient:apiClientMock
                                                        endpoint:endpoint
                                                      parameters:parameters
                                                    deserializer:deserializer
                                                      completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                                                          XCTAssertEqualObjects(object, (STPCard *)@"card");
                                                          XCTAssertEqualObjects(response, (NSHTTPURLResponse *)@"httpURLResponse");
                                                          XCTAssertEqualObjects(error, (NSError *)@"error");
                                                          [expectation fulfill];
                                                      }];
    XCTAssertEqualObjects(task, dataTaskMock);

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertNil(error);

        // Verify mocks
        OCMVerify([dataTaskMock resume]);

        OCMVerify([urlSessionMock dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            XCTAssertEqualObjects(request.URL, [NSURL URLWithString:@"https://api.stripe.com/endpoint?key=value"]);
            XCTAssertEqualObjects(request.HTTPMethod, @"GET");
            XCTAssertEqualObjects([[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], @"");
            return YES;
        }] completionHandler:[OCMArg any]]);

        OCMVerify([apiRequestMock parseResponse:[OCMArg isEqual:@"response"]
                                           body:[OCMArg isEqual:@"body"]
                                          error:[OCMArg isEqual:@"error"]
                                  deserializers:[OCMArg checkWithBlock:^BOOL(NSArray *deserializers) {
            XCTAssert([deserializers.firstObject isKindOfClass:[STPCard class]]);
            XCTAssertEqual(deserializers.count, (NSUInteger)1);
            return YES;
        }] completion:[OCMArg any]]);
    }];
}

- (void)testDeleteWithAPIClient {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];

    // Setup mocks
    NSURLSessionDataTask *dataTaskMock = OCMClassMock([NSURLSessionDataTask class]);

    NSURLSession *urlSessionMock = OCMClassMock([NSURLSession class]);
    OCMStub([urlSessionMock dataTaskWithRequest:[OCMArg any]
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
        completionHandler((NSData *)@"body", (NSURLResponse *)@"response", (NSError *)@"error");
        return YES;
    }]]).andReturn(dataTaskMock);

    STPAPIClient *apiClientMock = OCMClassMock([STPAPIClient class]);
    OCMStub([apiClientMock apiURL]).andReturn([NSURL URLWithString:@"https://api.stripe.com"]);
    OCMStub([apiClientMock urlSession]).andReturn(urlSessionMock);
    OCMStub([apiClientMock configuredRequestForURL:[OCMArg isKindOfClass:[NSURL class]]]).andDo(^(NSInvocation *invocation)
                                                                        {
                                                                            NSURL *urlArg;
                                                                            [invocation getArgument:&urlArg atIndex:2];
                                                                            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlArg];
                                                                            [invocation setReturnValue:&request];
                                                                            [invocation retainArguments];
                                                                        });

    id apiRequestMock = OCMClassMock([STPAPIRequest class]);
    OCMStub([apiRequestMock parseResponse:[OCMArg any]
                                     body:[OCMArg any]
                                    error:[OCMArg any]
                            deserializers:[OCMArg any]
                               completion:[OCMArg checkWithBlock:^BOOL(STPAPIResponseBlock completion) {
        completion((STPCard *)@"card", (NSHTTPURLResponse *)@"httpURLResponse", (NSError *)@"error");
        return YES;
    }]]);

    // Perform request
    NSString *endpoint = @"endpoint";
    NSDictionary *parameters = @{@"key": @"value"};
    STPCard *deserializer = [STPCard new];

    NSURLSessionDataTask *task = [STPAPIRequest deleteWithAPIClient:apiClientMock
                                                           endpoint:endpoint
                                                         parameters:parameters
                                                       deserializer:deserializer
                                                         completion:^(id<STPAPIResponseDecodable> object, NSHTTPURLResponse *response, NSError *error) {
                                                             XCTAssertEqualObjects(object, (STPCard *)@"card");
                                                             XCTAssertEqualObjects(response, (NSHTTPURLResponse *)@"httpURLResponse");
                                                             XCTAssertEqualObjects(error, (NSError *)@"error");
                                                             [expectation fulfill];
                                                         }];
    XCTAssertEqualObjects(task, dataTaskMock);

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        XCTAssertNil(error);

        // Verify mocks
        OCMVerify([dataTaskMock resume]);

        OCMVerify([urlSessionMock dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            XCTAssertEqualObjects(request.URL, [NSURL URLWithString:@"https://api.stripe.com/endpoint?key=value"]);
            XCTAssertEqualObjects(request.HTTPMethod, @"DELETE");
            XCTAssertEqualObjects([[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], @"");
            return YES;
        }] completionHandler:[OCMArg any]]);

        OCMVerify([apiRequestMock parseResponse:[OCMArg isEqual:@"response"]
                                           body:[OCMArg isEqual:@"body"]
                                          error:[OCMArg isEqual:@"error"]
                                  deserializers:[OCMArg checkWithBlock:^BOOL(NSArray *deserializers) {
            XCTAssert([deserializers.firstObject isKindOfClass:[STPCard class]]);
            XCTAssertEqual(deserializers.count, (NSUInteger)1);
            return YES;
        }] completion:[OCMArg any]]);
    }];
}

#pragma mark -

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

- (void)testParseResponseWithReturnedErrorOneDeserializer {
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

- (void)testParseResponseWithReturnedErrorMultipleDeserializers {
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
    NSArray *deserializers = @[[STPCard new], [STPSource new]];

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
    NSArray *deserializers = @[[STPCard new], [STPSource new]];

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
