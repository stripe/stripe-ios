//
//  STDSACSNetworkingManagerTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 4/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSStripe3DS2Error.h"
#import "STDSACSNetworkingManager.h"
#import "STDSTestJSONUtils.h"
#import "STDSErrorMessage.h"
#import "STDSChallengeResponseObject.h"

@interface STDSACSNetworkingManager (Private)
- (nullable id<STDSChallengeResponse>)decodeJSON:(NSDictionary *)dict error:(NSError * _Nullable *)outError;
@end

@interface STDSACSNetworkingManagerTest : XCTestCase

@end

@implementation STDSACSNetworkingManagerTest

- (void)testDecodeJSON {
    STDSACSNetworkingManager *manager = [[STDSACSNetworkingManager alloc] init];
    NSError *error;
    id decoded;
    
    // Unknown message type
    NSDictionary *unknownMessageDict = @{@"messageType": @"foo"};
    decoded = [manager decodeJSON:unknownMessageDict error:&error];
    XCTAssertEqual(error.code, STDSErrorCodeUnknownMessageType);
    XCTAssertNil(decoded);
    error = nil;
    
    // Error Message type
    NSDictionary *errorMessageDict = [STDSTestJSONUtils jsonNamed:@"ErrorMessage"];
    decoded = [manager decodeJSON:errorMessageDict error:&error];
    XCTAssertEqual(error.code, STDSErrorCodeReceivedErrorMessage);
    XCTAssertTrue([error.userInfo[STDSStripe3DS2ErrorMessageErrorKey] isKindOfClass:[STDSErrorMessage class]]);
    XCTAssertNil(decoded);
    error = nil;
    
    // ChallengeResponse message type
    NSDictionary *challengeResponseDict = [STDSTestJSONUtils jsonNamed:@"CRes"];
    decoded = [manager decodeJSON:challengeResponseDict error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([decoded isKindOfClass:[STDSChallengeResponseObject class]]);
}

@end
