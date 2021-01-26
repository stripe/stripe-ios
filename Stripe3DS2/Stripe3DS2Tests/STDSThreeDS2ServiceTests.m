//
//  STDSThreeDS2ServiceTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSAlreadyInitializedException.h"
#import "STDSConfigParameters.h"
#import "STDSInvalidInputException.h"
#import "STDSThreeDS2Service.h"
#import "STDSNotInitializedException.h"

@interface STDSThreeDS2ServiceTests : XCTestCase

@end

@implementation STDSThreeDS2ServiceTests

- (void)testInitialize {
    STDSThreeDS2Service *service = [[STDSThreeDS2Service alloc] init];
    XCTAssertNoThrow([service initializeWithConfig:[[STDSConfigParameters alloc] init]
                                            locale:nil
                                        uiSettings:nil],
                     @"Should not throw with valid input and first call to initialize");

    XCTAssertThrowsSpecific([service initializeWithConfig:[[STDSConfigParameters alloc] init]
                                                   locale:nil
                                               uiSettings:nil],
                            STDSAlreadyInitializedException,
                            @"Should throw STDSAlreadyInitializedException if called again with valid input.");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrowsSpecific([service initializeWithConfig:nil
                                                   locale:nil
                                               uiSettings:nil],
                            STDSInvalidInputException,
                            @"Should throw STDSInvalidInputException for nil config even if already initialized.");

    service = [[STDSThreeDS2Service alloc] init];
    XCTAssertThrowsSpecific([service initializeWithConfig:nil
                                                   locale:nil
                                               uiSettings:nil],
                            STDSInvalidInputException,
                            @"Should throw STDSInvalidInputException for nil config on first initialize.");
#pragma clang diagnostic pop

    XCTAssertNoThrow([service initializeWithConfig:[[STDSConfigParameters alloc] init]
                                            locale:nil
                                        uiSettings:nil],
                     @"Should not throw with valid input and first call to initialize even after invalid input");
    
    service = [[STDSThreeDS2Service alloc] init];
    XCTAssertThrowsSpecific(service.warnings, STDSNotInitializedException);

}

@end
