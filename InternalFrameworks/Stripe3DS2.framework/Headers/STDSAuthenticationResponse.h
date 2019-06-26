//
//  STDSAuthenticationResponse.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 2/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSJSONDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A native protocol representing the response sent by the 3DS Server.
 Only parameters relevant to performing 3DS2 authentication in the mobile SDK are exposed.
 */
@protocol STDSAuthenticationResponse <NSObject>

/// Universally unique transaction identifier assigned by the 3DS Server to identify a single transaction.
@property (nonatomic, readonly) NSString *threeDSServerTransactionID;

/// Indication of whether a challenge is required for the transaction to be authorised due to local/regional mandates or other variable.
@property (nonatomic, readonly, getter=isChallengeMandated) BOOL challengeMandated;

/// Indicates whether the ACS confirms utilisation of Decoupled Authentication and agrees to utilise Decoupled Authentication to authenticate the Cardholder.
@property (nonatomic, readonly) BOOL willUseDecoupledAuthentication;

/**
 DS assigned ACS identifier.
 Each DS can provide a unique ID to each ACS on an individual basis.
 */
@property (nonatomic, readonly, nullable) NSString *acsOperatorID;

/// Unique identifier assigned by the EMVCo Secretariat upon Testing and Approval.
@property (nonatomic, readonly, nullable) NSString *acsReferenceNumber;

/// Contains the JWS object (represented as a string) created by the ACS for the ARes message.
@property (nonatomic, readonly, nullable) NSString *acsSignedContent;

/// Universally Unique transaction identifier assigned by the ACS to identify a single transaction.
@property (nonatomic, readonly) NSString *acsTransactionID;

/// Fully qualified URL of the ACS to be used for the challenge.
@property (nonatomic, readonly, nullable) NSURL *acsURL;

/**
 Text provided by the ACS/Issuer to Cardholder during a Frictionless or Decoupled transaction. The Issuer can provide information to Cardholder.
 For example, “Additional authentication is needed for this transaction, please contact (Issuer Name) at xxx-xxx-xxxx.”
 */
@property (nonatomic, readonly, nullable) NSString *cardholderInfo;

/// EMVCo-assigned unique identifier to track approved DS.
@property (nonatomic, readonly, nullable) NSString *directoryServerReferenceNumber;

/// Universally unique transaction identifier assigned by the DS to identify a single transaction.
@property (nonatomic, readonly, nullable) NSString *directoryServerTransactionID;

/**
 Protocol version identifier This shall be the Protocol Version Number of the specification utilised by the system creating this message.
 The Message Version Number is set by the 3DS Server which originates the protocol with the AReq message.
 The Message Version Number does not change during a 3DS transaction.
 */
@property (nonatomic, readonly) NSString *protocolVersion;

/// Universally unique transaction identifier assigned by the 3DS SDK to identify a single transaction.
@property (nonatomic, readonly) NSString *sdkTransactionID;

@end

/// A utility to parse an STDSAuthenticationResponse from JSON
id<STDSAuthenticationResponse> _Nullable STDSAuthenticationResponseFromJSON(NSDictionary *json);

NS_ASSUME_NONNULL_END
