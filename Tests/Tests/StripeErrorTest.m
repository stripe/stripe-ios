//
//  StripeErrorTest.m
//  Stripe
//
//  Created by Ben Guo on 4/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSError+Stripe.h"
#import "StripeError.h"

@interface StripeErrorTest : XCTestCase

@end

@implementation StripeErrorTest

- (void)testEmptyResponse {
    NSDictionary *response = @{};
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertNil(error);
}

- (void)testResponseWithUnknownTypeAndNoMessage {
    NSDictionary *response = @{
                               @"error": @{
                                       @"type": @"foo",
                                       @"code": @"error_code"
                                       }
                               };
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertEqual(error.domain, StripeDomain);
    XCTAssertEqual(error.code, STPAPIError);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], [NSError stp_unexpectedErrorMessage]);
    XCTAssertEqual(error.userInfo[STPStripeErrorTypeKey], response[@"error"][@"type"]);
    XCTAssertEqual(error.userInfo[STPStripeErrorCodeKey], response[@"error"][@"code"]);
    XCTAssertTrue([error.userInfo[STPErrorMessageKey] hasPrefix:@"Could not interpret the error response"]);
}

- (void)testAPIError {
    NSDictionary *response = @{
                               @"error": @{
                                       @"type": @"api_error",
                                       @"message": @"some message"
                                       }
                               };
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertEqual(error.domain, StripeDomain);
    XCTAssertEqual(error.code, STPAPIError);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], [NSError stp_unexpectedErrorMessage]);
    XCTAssertEqualObjects(error.userInfo[STPErrorMessageKey], response[@"error"][@"message"]);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorTypeKey], response[@"error"][@"type"]);
}

- (void)testInvalidRequestErrorMissingParameter {
    NSDictionary *response = @{
                               @"error": @{
                                       @"type": @"invalid_request_error",
                                       @"message": @"The payment method `card` requires the parameter: card[exp_year].",
                                       @"param": @"card[exp_year]"
                                       }
                               };
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertEqual(error.domain, StripeDomain);
    XCTAssertEqual(error.code, STPInvalidRequestError);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], response[@"error"][@"message"]);
    XCTAssertEqualObjects(error.userInfo[STPErrorMessageKey], response[@"error"][@"message"]);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorTypeKey], response[@"error"][@"type"]);
    XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey], @"card[expYear]");
}

- (void)testInvalidRequestErrorIncorrectNumber {
    NSDictionary *response = @{
                               @"error": @{
                                       @"type": @"invalid_request_error",
                                       @"message": @"Your card number is incorrect.",
                                       @"code": @"incorrect_number"
                                       }
                               };
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertEqual(error.domain, StripeDomain);
    XCTAssertEqual(error.code, STPInvalidRequestError);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], [NSError stp_cardErrorInvalidNumberUserMessage]);
    XCTAssertEqualObjects(error.userInfo[STPCardErrorCodeKey], STPIncorrectNumber);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorTypeKey], response[@"error"][@"type"]);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorCodeKey], response[@"error"][@"code"]);
    XCTAssertEqualObjects(error.userInfo[STPErrorMessageKey], response[@"error"][@"message"]);
}

- (void)testCardErrorIncorrectNumber {
    NSDictionary *response = @{
                               @"error": @{
                                       @"type": @"card_error",
                                       @"message": @"Your card number is incorrect.",
                                       @"code": @"incorrect_number"
                                       }
                               };
    NSError *error = [NSError stp_errorFromStripeResponse:response];
    XCTAssertEqual(error.domain, StripeDomain);
    XCTAssertEqual(error.code, STPCardError);
    XCTAssertEqualObjects(error.userInfo[NSLocalizedDescriptionKey], [NSError stp_cardErrorInvalidNumberUserMessage]);
    XCTAssertEqualObjects(error.userInfo[STPCardErrorCodeKey], STPIncorrectNumber);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorTypeKey], response[@"error"][@"type"]);
    XCTAssertEqualObjects(error.userInfo[STPStripeErrorCodeKey], response[@"error"][@"code"]);
    XCTAssertEqualObjects(error.userInfo[STPErrorMessageKey], response[@"error"][@"message"]);
}

@end
