//
//  STDSChallengeRequestParametersTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 4/1/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSChallengeRequestParameters.h"
#import "STDSJSONEncoder.h"

@interface STDSChallengeRequestParametersTest : XCTestCase

@end

@implementation STDSChallengeRequestParametersTest

#pragma mark - STDSJSONEncodable

- (void)testPropertyNamesToJSONKeysMapping {
    STDSChallengeRequestParameters *params = [[STDSChallengeRequestParameters alloc] initWithThreeDSServerTransactionIdentifier:@"server id"
                                                                                                       acsTransactionIdentifier:@"acs id"
                                                                                                                 messageVersion:@"message version"
                                                                                                       sdkTransactionIdentifier:@"sdk id"
                                                                                                                 sdkCounterStoA:0];
    
    NSDictionary *mapping = [STDSChallengeRequestParameters propertyNamesToJSONKeysMapping];
    
    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([params respondsToSelector:NSSelectorFromString(propertyName)]);
    }
    
    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }
    
    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:[STDSJSONEncoder dictionaryForObject:params]]);
}

- (void)testNextChallengeRequestParametersIncrementsCounter {
    STDSChallengeRequestParameters *params = [[STDSChallengeRequestParameters alloc] initWithThreeDSServerTransactionIdentifier:@"server id"
                                                                                                       acsTransactionIdentifier:@"acs id"
                                                                                                                 messageVersion:@"message version"
                                                                                                       sdkTransactionIdentifier:@"sdk id"
                                                                                                                 sdkCounterStoA:0];
    for (NSInteger i = 0; i < 1000; i++) {
        XCTAssertEqual(params.sdkCounterStoA.length, 3);
        XCTAssertEqual(params.sdkCounterStoA.integerValue, i);
        params = [params nextChallengeRequestParametersByIncrementCounter];
    }
}

- (void)testEmptyChallengeDataEntryField {
    STDSChallengeRequestParameters *params = [[STDSChallengeRequestParameters alloc] initWithThreeDSServerTransactionIdentifier:@"server id"
                                                                                                       acsTransactionIdentifier:@"acs id"
                                                                                                                 messageVersion:@"message version"
                                                                                                       sdkTransactionIdentifier:@"sdk id"
                                                                                                                 sdkCounterStoA:0];
    params.challengeDataEntry = @"";
    XCTAssertNil(params.challengeDataEntry);
}

@end
