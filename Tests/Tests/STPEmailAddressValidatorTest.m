//
//  STPEmailAddressValidatorTest.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPEmailAddressValidator.h"

@interface STPEmailAddressValidatorTest : XCTestCase
@end

@implementation STPEmailAddressValidatorTest

- (void)testValidEmails {
    NSArray *validEmails = @[
                             @"test@test.com",
                             @"test+thing@test.com.nz",
                             @"a@b.c",
                             @"A@b.c",
                             ];
    for (NSString *email in validEmails) {
        XCTAssert([STPEmailAddressValidator stringIsValidEmailAddress:email]);
    }
}

- (void)testInvalidEmails {
    NSArray *invalidEmails = @[
                               @"",
                               @"google.com",
                               @"asdf",
                               @"asdg@c"
                               ];
    for (NSString *email in invalidEmails) {
        XCTAssertFalse([STPEmailAddressValidator stringIsValidEmailAddress:email]);
    }
}

@end
