//
//  STP3DS2AuthenticateResponse.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@protocol STDSAuthenticationResponse;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STP3DS2AuthenticateResponseState) {
    /**
     Unknown Authenticate Response state
     */
    STP3DS2AuthenticateResponseStateUnknown = 0,

    /**
     State indicating that a challenge flow needs to be applied
     */
    STP3DS2AuthenticateResponseStateChallengeRequired,

    /**
     State indicating that the authentication succeeded
     */
    STP3DS2AuthenticateResponseStateSucceeded,
};

@interface STP3DS2AuthenticateResponse : NSObject <STPAPIResponseDecodable>

/**
 The Authentication Response received from the Access Control Server
 */
@property(nonatomic, nullable, readonly) id<STDSAuthenticationResponse> authenticationResponse;

/**
 When the 3DS2 Authenticate Response was created.
 */
@property (nonatomic, nullable, readonly) NSDate *created;

/**
 Whether or not this Authenticate Response was created in livemode.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 The identifier for the Source associated with this Authenticate Response
 */
@property (nonatomic, nullable, readonly) NSString *sourceID;

/**
 A fallback URL to redirect to instead of running native 3DS2
 */
@property (nonatomic, nullable, readonly) NSURL *fallbackURL;

/**
 The state of the authentication
 */
@property (readonly) STP3DS2AuthenticateResponseState state;

@end

NS_ASSUME_NONNULL_END
