//
//  STDSDeviceInformationManagerTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/24/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSDeviceInformation.h"
#import "STDSDeviceInformationManager.h"
#import "STDSWarning.h"

@interface STDSDeviceInformationManagerTests : XCTestCase

@end

@implementation STDSDeviceInformationManagerTests

- (void)testDeviceInformation {
    STDSDeviceInformation *deviceInformation = [STDSDeviceInformationManager deviceInformationWithWarnings:@[] ignoringRestrictions:NO];
    XCTAssertEqualObjects(deviceInformation.dictionaryValue[@"DV"], @"1.4", @"Device data version check.");
    XCTAssertNotNil(deviceInformation.dictionaryValue[@"DD"], @"Device data should be non-nil");
    XCTAssertNotNil(deviceInformation.dictionaryValue[@"DPNA"], @"Param not available should be non-nil in simulator");
    XCTAssertNil(deviceInformation.dictionaryValue[@"SW"]);

    deviceInformation = [STDSDeviceInformationManager deviceInformationWithWarnings:@[[[STDSWarning alloc] initWithIdentifier:@"WARNING_1" message:@"" severity:STDSWarningSeverityMedium], [[STDSWarning alloc] initWithIdentifier:@"WARNING_2" message:@"" severity:STDSWarningSeverityMedium], ] ignoringRestrictions:NO];
    NSArray<NSString *> *warningIDs = @[@"WARNING_1", @"WARNING_2"];
    XCTAssertEqualObjects(deviceInformation.dictionaryValue[@"SW"], warningIDs, @"Failed to set warning identifiers correctly");
}

@end
