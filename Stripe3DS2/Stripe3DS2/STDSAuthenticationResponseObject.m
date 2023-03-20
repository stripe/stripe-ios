//
//  STDSAuthenticationResponseObject.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 5/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSAuthenticationResponseObject.h"

#import "NSDictionary+DecodingHelpers.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSAuthenticationResponseObject

@synthesize acsOperatorID = _acsOperatorID;
@synthesize acsReferenceNumber = _acsReferenceNumber;
@synthesize acsSignedContent = _acsSignedContent;
@synthesize acsTransactionID = _acsTransactionID;
@synthesize acsURL = _acsURL;
@synthesize cardholderInfo = _cardholderInfo;
@synthesize status = _status;
@synthesize challengeRequired = _challengeRequired;
@synthesize directoryServerReferenceNumber = _directoryServerReferenceNumber;
@synthesize directoryServerTransactionID = _directoryServerTransactionID;
@synthesize protocolVersion = _protocolVersion;
@synthesize sdkTransactionID = _sdkTransactionID;
@synthesize threeDSServerTransactionID = _threeDSServerTransactionID;
@synthesize willUseDecoupledAuthentication = _willUseDecoupledAuthentication;

+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError **)outError {
    if (json == nil) {
        return nil;
    }
    STDSAuthenticationResponseObject *response = [[self alloc] init];
    NSError *error = nil;

    response->_threeDSServerTransactionID = [[json _stds_stringForKey:@"threeDSServerTransID" required:YES error:&error] copy];
    NSString *transStatusString = [json _stds_stringForKey:@"transStatus" required:NO error:&error];
    response->_status = [self statusTypeForString:transStatusString];
    response->_challengeRequired = (response->_status == STDSACSStatusTypeChallengeRequired);
    response->_willUseDecoupledAuthentication = [[json _stds_boolForKey:@"acsDecConInd" required:NO error:&error] boolValue];
    response->_acsOperatorID = [[json _stds_stringForKey:@"acsOperatorID" required:NO error:&error] copy];
    response->_acsReferenceNumber = [[json _stds_stringForKey:@"acsReferenceNumber" required:NO error:&error] copy];
    response->_acsSignedContent = [[json _stds_stringForKey:@"acsSignedContent" required:NO error:&error] copy];
    response->_acsTransactionID = [[json _stds_stringForKey:@"acsTransID" required:YES error:&error] copy];
    response->_acsURL = [json _stds_urlForKey:@"acsURL" required:NO error:&error];
    response->_cardholderInfo = [[json _stds_stringForKey:@"cardholderInfo" required:NO error:&error] copy];
    response->_directoryServerReferenceNumber = [[json _stds_stringForKey:@"dsReferenceNumber" required:NO error:&error] copy];
    response->_directoryServerTransactionID = [[json _stds_stringForKey:@"dsTransID" required:NO error:&error] copy];
    response->_protocolVersion = [[json _stds_stringForKey:@"messageVersion" required:YES error:&error] copy];
    response->_sdkTransactionID = [[json _stds_stringForKey:@"sdkTransID" required:YES error:&error] copy];

    if (error != nil) {
        if (outError != nil) {
            *outError = error;
        }

        return nil;
    }

    return response;
}

+ (STDSACSStatusType)statusTypeForString:(NSString *)statusString {
    if ([statusString isEqualToString:@"Y"]) {
        return STDSACSStatusTypeAuthenticated;
    }
    if ([statusString isEqualToString:@"C"]) {
        return STDSACSStatusTypeChallengeRequired;
    }
    if ([statusString isEqualToString:@"D"]) {
        return STDSACSStatusTypeDecoupledAuthentication;
    }
    if ([statusString isEqualToString:@"N"]) {
        return STDSACSStatusTypeNotAuthenticated;
    }
    if ([statusString isEqualToString:@"A"]) {
        return STDSACSStatusTypeProofGenerated;
    }
    if ([statusString isEqualToString:@"U"]) {
        return STDSACSStatusTypeError;
    }
    if ([statusString isEqualToString:@"R"]) {
        return STDSACSStatusTypeRejected;
    }
    if ([statusString isEqualToString:@"I"]) {
        return STDSACSStatusTypeInformationalOnly;
    }
    return STDSACSStatusTypeUnknown;
}

@end

id<STDSAuthenticationResponse> _Nullable STDSAuthenticationResponseFromJSON(NSDictionary *json) {
    return [STDSAuthenticationResponseObject decodedObjectFromJSON:json error:NULL];
}

NS_ASSUME_NONNULL_END
