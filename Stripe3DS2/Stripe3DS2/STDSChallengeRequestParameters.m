//
//  STDSChallengeRequestParameters.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 4/1/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeRequestParameters.h"

#import "STDSChallengeParameters.h"

@implementation STDSChallengeRequestParameters

- (instancetype)initWithChallengeParameters:(STDSChallengeParameters *)challengeParams
                      transactionIdentifier:(NSString *)transactionIdentifier
                             messageVersion:(NSString *)messageVersion {
    return [self initWithThreeDSServerTransactionIdentifier:challengeParams.threeDSServerTransactionID
                                   acsTransactionIdentifier:challengeParams.acsTransactionID
                                             messageVersion:messageVersion
                                   sdkTransactionIdentifier:transactionIdentifier
                                            requestorAppUrl:challengeParams.threeDSRequestorAppURL
                                             sdkCounterStoA:0];
}

- (instancetype)initWithThreeDSServerTransactionIdentifier:(NSString *)threeDSServerTransactionIdentifier
                                  acsTransactionIdentifier:(NSString *)acsTransactionIdentifier
                                            messageVersion:(NSString *)messageVersion
                                  sdkTransactionIdentifier:(NSString *)sdkTransactionIdentifier
                                           requestorAppUrl:(NSString *)requestorAppUrl
                                            sdkCounterStoA:(NSInteger)sdkCounterStoA {
    self = [super init];
    if (self) {
        _messageType = @"CReq";
        _threeDSServerTransactionIdentifier = [threeDSServerTransactionIdentifier copy];
        _acsTransactionIdentifier = [acsTransactionIdentifier copy];
        _messageVersion = [messageVersion copy];
        _sdkTransactionIdentifier = [sdkTransactionIdentifier copy];
        _threeDSRequestorAppURL = [requestorAppUrl copy];
        _sdkCounterStoA = [NSString stringWithFormat:@"%03ld", (long)sdkCounterStoA];
    }
    return self;
}

- (instancetype)nextChallengeRequestParametersByIncrementCounter {
    NSInteger incrementedCounter = [self.sdkCounterStoA intValue] + 1;
    return [[STDSChallengeRequestParameters alloc] initWithThreeDSServerTransactionIdentifier:self.threeDSServerTransactionIdentifier
                                                                     acsTransactionIdentifier:self.acsTransactionIdentifier
                                                                               messageVersion:self.messageVersion
                                                                     sdkTransactionIdentifier:self.sdkTransactionIdentifier
                                                                              requestorAppUrl:self.threeDSRequestorAppURL // TC_SDK_10209_001
                                                                               sdkCounterStoA:incrementedCounter];
}

- (void)setChallengeDataEntry:(NSString *)challengeDataEntry {
    // [Req 40] ...if the cardholder has submitted the response without entering any data in the UI, the Challenge Data Entry field shall not be present in the CReq message.
    if (challengeDataEntry.length == 0) {
        _challengeDataEntry = nil;
        _challengeNoEntry = @"Y";
    } else {
        _challengeDataEntry = [challengeDataEntry copy];
        _challengeNoEntry = nil;
    }
}

#pragma mark - Helpers

- (nullable NSString *)challengeCancelString {
    if (self.challengeCancel == nil) {
        return nil;
    }
    
    STDSChallengeCancelType challengeCancelType = (STDSChallengeCancelType)[self.challengeCancel integerValue];
    switch (challengeCancelType) {
        case STDSChallengeCancelTypeCardholderSelectedCancel:
            return @"01";
        case STDSChallengeCancelTypeTransactionTimedOut:
            return @"08";
    }
    return @"07"; // Unknown
}

#pragma mark - STDSJSONEncodable

+ (NSDictionary *)propertyNamesToJSONKeysMapping {
    return @{
             NSStringFromSelector(@selector(threeDSServerTransactionIdentifier)): @"threeDSServerTransID",
             NSStringFromSelector(@selector(acsTransactionIdentifier)): @"acsTransID",
             NSStringFromSelector(@selector(threeDSRequestorAppURL)): @"threeDSRequestorAppURL",
             NSStringFromSelector(@selector(challengeCancelString)): @"challengeCancel",
             NSStringFromSelector(@selector(challengeDataEntry)): @"challengeDataEntry",
             NSStringFromSelector(@selector(challengeHTMLDataEntry)): @"challengeHTMLDataEntry",
             NSStringFromSelector(@selector(challengeNoEntry)): @"challengeNoEntry",
             NSStringFromSelector(@selector(messageExtension)): @"messageExtension",
             NSStringFromSelector(@selector(messageVersion)): @"messageVersion",
             NSStringFromSelector(@selector(messageType)): @"messageType",
             NSStringFromSelector(@selector(oobContinue)): @"oobContinue",
             NSStringFromSelector(@selector(resendChallenge)): @"resendChallenge",
             NSStringFromSelector(@selector(sdkTransactionIdentifier)): @"sdkTransID",
             NSStringFromSelector(@selector(sdkCounterStoA)): @"sdkCounterStoA",
             NSStringFromSelector(@selector(whitelistingDataEntry)): @"whitelistingDataEntry",
             };
}

@end
