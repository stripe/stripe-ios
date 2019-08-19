//
//  STPPaymentIntentLastPaymentErrorTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/Stripe.h>
#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentIntentLastPaymentError (Testing)
+ (STPPaymentIntentLastPaymentErrorType)typeFromString:(NSString *)string;
@end

@interface STPPaymentIntentLastpaymentErrorTest : XCTestCase

@end

@implementation STPPaymentIntentLastpaymentErrorTest

- (void)testTypeFromString {
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"api_connection_error"], STPPaymentIntentLastPaymentErrorTypeAPIConnection);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"API_CONNECTION_ERROR"], STPPaymentIntentLastPaymentErrorTypeAPIConnection);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"api_error"], STPPaymentIntentLastPaymentErrorTypeAPI);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"API_ERROR"], STPPaymentIntentLastPaymentErrorTypeAPI);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"authentication_error"], STPPaymentIntentLastPaymentErrorTypeAuthentication);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"AUTHENTICATION_ERROR"], STPPaymentIntentLastPaymentErrorTypeAuthentication);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"card_error"], STPPaymentIntentLastPaymentErrorTypeCard);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"CARD_ERROR"], STPPaymentIntentLastPaymentErrorTypeCard);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"idempotency_error"], STPPaymentIntentLastPaymentErrorTypeIdempotency);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"IDEMPOTENCY_ERROR"], STPPaymentIntentLastPaymentErrorTypeIdempotency);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"invalid_request_error"], STPPaymentIntentLastPaymentErrorTypeInvalidRequest);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"INVALID_REQUEST_ERROR"], STPPaymentIntentLastPaymentErrorTypeInvalidRequest);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"rate_limit_error"], STPPaymentIntentLastPaymentErrorTypeRateLimit);
    XCTAssertEqual([STPPaymentIntentLastPaymentError typeFromString:@"RATE_LIMIT_ERROR"], STPPaymentIntentLastPaymentErrorTypeRateLimit);
}

#pragma mark - STPAPIResponseDecodable Tests

// STPPaymentIntentLastError is a sub-object of STPPaymentIntent, see STPPaymentIntentTest

@end
