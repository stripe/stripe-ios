//
//  STDSAuthenticationResponseTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 5/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSAuthenticationResponseObject.h"
#import "STDSTestJSONUtils.h"

@interface STDSAuthenticationResponseTests : XCTestCase

@end

@implementation STDSAuthenticationResponseTests

- (void)testInitWithJSON {
    NSError *error = nil;
    STDSAuthenticationResponseObject *ares = [STDSAuthenticationResponseObject decodedObjectFromJSON:[STDSTestJSONUtils jsonNamed:@"ARes"] error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(ares, @"Failed to create an ares parsed from JSON");

    id<STDSAuthenticationResponse> authResponse = STDSAuthenticationResponseFromJSON([STDSTestJSONUtils jsonNamed:@"ARes"]);
    XCTAssertNotNil(authResponse, @"Failed to create an ares parsed from JSON");
    XCTAssert(authResponse.isChallengeRequired, @"ares did not indicate that a challenge was required");
}

@end
