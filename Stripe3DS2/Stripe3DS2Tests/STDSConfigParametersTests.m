//
//  STDSConfigParametersTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 2/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSConfigParameters.h"
#import "STDSInvalidInputException.h"

@interface STDSConfigParametersTests : XCTestCase

@end

@implementation STDSConfigParametersTests

- (void)testStandardParameters {
    STDSConfigParameters *defaultParameters = [[STDSConfigParameters alloc] initWithStandardParameters];
    XCTAssertNotNil(defaultParameters, @"Should return a non-nil instance");
}

- (void)testAddRead {
    STDSConfigParameters *parameters = [[STDSConfigParameters alloc] init];
    XCTAssertNoThrow([parameters addParameterNamed:@"testName" withValue:@"testValue"], @"Should not throw with non-nil name and value.");
    NSString *paramValue = nil;
    XCTAssertNoThrow(paramValue = [parameters parameterValue:@"testName"], @"Should not throw with non-nil name.");
    XCTAssertEqual(paramValue, @"testValue", @"Returned value does not match expectation.");
}

- (void)testDefaultGroup {
    STDSConfigParameters *parameters = [[STDSConfigParameters alloc] init];
    XCTAssertNoThrow([parameters addParameterNamed:@"testName" withValue:@"testValue"], @"Should not throw with non-nil name and value.");
    XCTAssertNoThrow([parameters addParameterNamed:@"testName" withValue:@"testValue2" toGroup:@"otherGroup"], @"Should not throw with non-nil name, value, and group.");
    NSString *paramValue = nil;
    XCTAssertNoThrow(paramValue = [parameters parameterValue:@"testName"], @"Should not throw with non-nil name.");
    XCTAssertEqual(paramValue, @"testValue", @"Returned value does not match expectation. Should default to default group's value.");
    XCTAssertNoThrow(paramValue = [parameters parameterValue:@"testName" inGroup:@"otherGroup"], @"Should not throw with non-nil name and group name.");
    XCTAssertEqual(paramValue, @"testValue2", @"Returned value does not match expectation. Should read from custom group.");
}

- (void)testExceptions {
    STDSConfigParameters *parameters = [[STDSConfigParameters alloc] init];
    XCTAssertNoThrow([parameters addParameterNamed:@"testParam" withValue:@"testValue" toGroup:nil], @"Should not throw with nil group.");

    XCTAssertThrowsSpecific([parameters addParameterNamed:@"testParam" withValue:@"value2"], STDSInvalidInputException, @"Should throw STDSInvalidInputException if trying to override testParam value.");
    [parameters addParameterNamed:@"testParam" withValue:@"testValue" toGroup:@"otherGroup"];
    XCTAssertThrowsSpecific([parameters addParameterNamed:@"testParam" withValue:@"value2" toGroup:@"otherGroup"], STDSInvalidInputException, @"Should throw STDSInvalidInputException if trying to override testParam value in non-default group.");
}

- (void)testRemove {
    STDSConfigParameters *parameters = [[STDSConfigParameters alloc] init];

    [parameters addParameterNamed:@"testParam" withValue:@"testValue"];
    [parameters addParameterNamed:@"testParam" withValue:@"testValue2" toGroup:@"otherGroup"];
    XCTAssertEqual([parameters removeParameterNamed:@"testParam"], @"testValue", @"Should return testValue when removing.");
    XCTAssertNil([parameters parameterValue:@"testParam"]);
    XCTAssertNotNil([parameters parameterValue:@"testParam" inGroup:@"otherGroup"], @"Should only remove param in specified group.");

    XCTAssertNil([parameters removeParameterNamed:@"testParam"], @"Should return nil if removing a non-existant parameter.");

    XCTAssertEqual([parameters removeParameterNamed:@"testParam" fromGroup:@"otherGroup"], @"testValue2", @"Should return group-specific value when removing.");
}

@end
