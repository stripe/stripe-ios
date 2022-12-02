//
//  STPSetupIntentLastSetupErrorTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@import Stripe;
#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPSetupIntentLastSetupError (Testing)
+ (STPSetupIntentLastSetupErrorType)typeFromString:(NSString *)string;
@end

@interface STPSetupIntentLastSetupErrorTest : XCTestCase

@end

@implementation STPSetupIntentLastSetupErrorTest

- (void)testTypeFromString {
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"api_connection_error"], STPSetupIntentLastSetupErrorTypeAPIConnection);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"API_CONNECTION_ERROR"], STPSetupIntentLastSetupErrorTypeAPIConnection);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"api_error"], STPSetupIntentLastSetupErrorTypeAPI);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"API_ERROR"], STPSetupIntentLastSetupErrorTypeAPI);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"authentication_error"], STPSetupIntentLastSetupErrorTypeAuthentication);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"AUTHENTICATION_ERROR"], STPSetupIntentLastSetupErrorTypeAuthentication);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"card_error"], STPSetupIntentLastSetupErrorTypeCard);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"CARD_ERROR"], STPSetupIntentLastSetupErrorTypeCard);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"idempotency_error"], STPSetupIntentLastSetupErrorTypeIdempotency);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"IDEMPOTENCY_ERROR"], STPSetupIntentLastSetupErrorTypeIdempotency);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"invalid_request_error"], STPSetupIntentLastSetupErrorTypeInvalidRequest);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"INVALID_REQUEST_ERROR"], STPSetupIntentLastSetupErrorTypeInvalidRequest);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"rate_limit_error"], STPSetupIntentLastSetupErrorTypeRateLimit);
    XCTAssertEqual([STPSetupIntentLastSetupError typeFromString:@"RATE_LIMIT_ERROR"], STPSetupIntentLastSetupErrorTypeRateLimit);
}

#pragma mark - STPAPIResponseDecodable Tests

// STPSetupIntentLastError is a sub-object of STPSetupIntent, see STPSetupIntentTest


@end
