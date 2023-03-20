//
//  STDSChallengeParameters.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 2/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeParameters.h"

#import "STDSAuthenticationResponse.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSChallengeParameters

- (instancetype)initWithAuthenticationResponse:(id<STDSAuthenticationResponse>)authResponse {
    self = [self init];
    if (self) {
        _threeDSServerTransactionID = [authResponse.threeDSServerTransactionID copy];
        _acsTransactionID = [authResponse.acsTransactionID copy];
        _acsReferenceNumber = [authResponse.acsReferenceNumber copy];
        _acsSignedContent = [authResponse.acsSignedContent copy];
    }

    return self;
}

@end

NS_ASSUME_NONNULL_END
