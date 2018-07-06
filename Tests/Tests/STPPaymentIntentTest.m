//
//  STPPaymentIntentTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentIntent.h"
#import "STPPaymentIntent+Private.h"

@interface STPPaymentIntentTest : XCTestCase

@end

@implementation STPPaymentIntentTest

- (void)testIdentifierFromSecret {
    XCTAssertEqualObjects([STPPaymentIntent idFromClientSecret:@"pi_123_secret_XYZ"],
                          @"pi_123");
    XCTAssertEqualObjects([STPPaymentIntent idFromClientSecret:@"pi_123_secret_RandomlyContains_secret_WhichIsFine"],
                          @"pi_123");

    XCTAssertNil([STPPaymentIntent idFromClientSecret:@""]);
    XCTAssertNil([STPPaymentIntent idFromClientSecret:@"po_123_secret_HasBadPrefix"]);
    XCTAssertNil([STPPaymentIntent idFromClientSecret:@"MissingSentinalForSplitting"]);
}

- (void)testStatusFromString {
    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_source"],
                   STPPaymentIntentStatusRequiresSource);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_SOURCE"],
                   STPPaymentIntentStatusRequiresSource);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_confirmation"],
                   STPPaymentIntentStatusRequiresConfirmation);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_CONFIRMATION"],
                   STPPaymentIntentStatusRequiresConfirmation);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_source_action"],
                   STPPaymentIntentStatusRequiresSourceAction);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_SOURCE_ACTION"],
                   STPPaymentIntentStatusRequiresSourceAction);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"processing"],
                   STPPaymentIntentStatusProcessing);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"PROCESSING"],
                   STPPaymentIntentStatusProcessing);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"succeeded"],
                   STPPaymentIntentStatusSucceeded);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"SUCCEEDED"],
                   STPPaymentIntentStatusSucceeded);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_capture"],
                   STPPaymentIntentStatusRequiresCapture);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_CAPTURE"],
                   STPPaymentIntentStatusRequiresCapture);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"canceled"],
                   STPPaymentIntentStatusCanceled);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"CANCELED"],
                   STPPaymentIntentStatusCanceled);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"garbage"],
                   STPPaymentIntentStatusUnknown);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"GARBAGE"],
                   STPPaymentIntentStatusUnknown);
}

- (void)testCaptureMethodFromString {
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"manual"],
                   STPPaymentIntentCaptureMethodManual);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"MANUAL"],
                   STPPaymentIntentCaptureMethodManual);

    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"automatic"],
                   STPPaymentIntentCaptureMethodAutomatic);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"AUTOMATIC"],
                   STPPaymentIntentCaptureMethodAutomatic);

    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"garbage"],
                   STPPaymentIntentCaptureMethodUnknown);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"GARBAGE"],
                   STPPaymentIntentCaptureMethodUnknown);
}

- (void)testConfirmationMethodFromString {
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"secret"],
                   STPPaymentIntentConfirmationMethodSecret);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"SECRET"],
                   STPPaymentIntentConfirmationMethodSecret);

    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"public"],
                   STPPaymentIntentConfirmationMethodPublic);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"PUBLIC"],
                   STPPaymentIntentConfirmationMethodPublic);

    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"garbage"],
                   STPPaymentIntentConfirmationMethodUnknown);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"GARBAGE"],
                   STPPaymentIntentConfirmationMethodUnknown);
}

// FIXME: add description + STPAPIResponseDecodable Tests (see STPSourceTest, STPSourceOwnerTest)

@end
