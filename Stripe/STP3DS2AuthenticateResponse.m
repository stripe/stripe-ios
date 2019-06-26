//
//  STP3DS2AuthenticateResponse.m
//  StripeiOS
//
//  Created by Cameron Sabol on 5/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STP3DS2AuthenticateResponse.h"

#import <Stripe3DS2/Stripe3DS2.h>

#import "NSDictionary+Stripe.h"
#import "NSArray+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STP3DS2AuthenticateResponse

@synthesize allResponseFields = _allResponseFields;

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    NSDictionary *authenticationResponseJSON = [dict stp_dictionaryForKey:@"ares"];
    if (authenticationResponseJSON == nil) {
        return nil;
    }
    id<STDSAuthenticationResponse> authenticationResponse = STDSAuthenticationResponseFromJSON(authenticationResponseJSON);
    if (authenticationResponse == nil) {
        return nil;
    }

    NSString *stateString = [dict stp_stringForKey:@"state"];
    STP3DS2AuthenticateResponseState state = STP3DS2AuthenticateResponseStateUnknown;
    if ([stateString isEqualToString:@"succeeded"]) {
        state = STP3DS2AuthenticateResponseStateSucceeded;
    } else if ([stateString isEqualToString:@"challenge_required"]) {
        state = STP3DS2AuthenticateResponseStateChallengeRequired;
    }

    if (state == STP3DS2AuthenticateResponseStateUnknown) {
        return nil;
    }

    STP3DS2AuthenticateResponse *authResponse = [self new];
    authResponse->_authenticationResponse = authenticationResponse;
    authResponse->_state = state;
    authResponse->_created = [dict stp_dateForKey:@"created"];
    authResponse->_livemode = [dict stp_boolForKey:@"livemode" or:YES];
    authResponse->_sourceID = [dict stp_stringForKey:@"source"];
    authResponse->_allResponseFields = dict;

    return authResponse;
}

@end

NS_ASSUME_NONNULL_END
