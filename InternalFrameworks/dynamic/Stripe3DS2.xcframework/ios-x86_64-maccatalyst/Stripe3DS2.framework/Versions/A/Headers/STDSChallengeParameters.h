//
//  STDSChallengeParameters.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 2/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STDSAuthenticationResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSChallengeParameters` contains information from the 3DS Server's
 authentication response that are used by the 3DS2 SDK to initiate
 the challenge flow.
 */
@interface STDSChallengeParameters : NSObject

/**
 Convenience intiializer to create an instace of `STDSChallengeParameters` from an
 `STDSAuthenticationResponse`
 */
- (instancetype)initWithAuthenticationResponse:(id<STDSAuthenticationResponse>)authResponse;

/**
 Transaction identifier assigned by the 3DS Server to uniquely identify
 a transaction.
 */
@property (nonatomic, copy) NSString *threeDSServerTransactionID;

/**
 Transaction identifier assigned by the Access Control Server (ACS)
 to uniquely identify a transaction.
 */
@property (nonatomic, copy) NSString *acsTransactionID;

/**
 The reference number of the relevant Access Control Server.
 */
@property (nonatomic, copy) NSString *acsReferenceNumber;

/**
 The encrypted message sent by the Access Control Server
 containing the ACS URL, epthemeral public key, and the
 3DS2 SDK ephemeral public key.
 */
@property (nonatomic, copy) NSString *acsSignedContent;

/**
 The URL for the application that is requesting 3DS2 verification.
 This property can be optionally set and will be included with the
 messages sent to the Directory Server during the challenge flow.
 */
@property (nonatomic, copy, nullable) NSString *threeDSRequestorAppURL;

@end

NS_ASSUME_NONNULL_END
