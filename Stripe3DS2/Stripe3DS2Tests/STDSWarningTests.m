//
//  STDSWarningTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 2/12/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSWarning.h"

@interface STDSWarningTests : XCTestCase

@end

@implementation STDSWarningTests

- (void)testWarning {
    STDSWarning *warning = [[STDSWarning alloc] initWithIdentifier:@"test_id" message:@"test_message" severity:STDSWarningSeverityMedium];
    XCTAssertEqual(warning.identifier, @"test_id", @"Identifier was not set correctly.");
    XCTAssertEqual(warning.message, @"test_message", @"Message was not set correctly.");
    XCTAssertEqual(warning.severity, STDSWarningSeverityMedium, @"Severity was not set correctly.");
}

@end
