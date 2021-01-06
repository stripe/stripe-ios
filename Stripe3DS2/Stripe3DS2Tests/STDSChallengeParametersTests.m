//
//  STDSChallengeParametersTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 2/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSAuthenticationResponseObject.h"
#import "STDSChallengeParameters.h"

@interface TestAuthResponse: STDSAuthenticationResponseObject

@end

@interface STDSChallengeParametersTests : XCTestCase

@end

@implementation STDSChallengeParametersTests

- (void)testInitWithAuthResponse {
    STDSChallengeParameters *params = [[STDSChallengeParameters alloc] initWithAuthenticationResponse:[[TestAuthResponse alloc] init]];

    XCTAssertEqual(params.threeDSServerTransactionID, @"test_threeDSServerTransactionID", @"Failed to set test_threeDSServerTransactionID");
    XCTAssertEqual(params.acsTransactionID, @"test_acsTransactionID", @"Failed to set test_acsTransactionID");
    XCTAssertEqual(params.acsReferenceNumber, @"test_acsReferenceNumber", @"Failed to set test_acsReferenceNumber");
    XCTAssertEqual(params.acsSignedContent, @"test_acsSignedContent", @"Failed to set test_acsSignedContent");
    XCTAssertNil(params.threeDSRequestorAppURL, @"Should not have set threeDSRequestorAppURL");
}

@end

#pragma mark - TestAuthResponse

@implementation TestAuthResponse

- (NSString *)threeDSServerTransactionID {
    return @"test_threeDSServerTransactionID";
}

- (NSString *)acsTransactionID {
    return @"test_acsTransactionID";
}

- (NSString *)acsReferenceNumber {
    return @"test_acsReferenceNumber";
}

- (NSString *)acsSignedContent {
    return @"test_acsSignedContent";
}

@end
