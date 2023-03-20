//
//  STDSEphemeralKeyPair.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSDirectoryServerCertificate;
@class STDSEllipticCurvePoint;

#import "STDSDirectoryServer.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSEphemeralKeyPair : NSObject

/// Creates a returns a new elliptic curve key pair using curve P-256
+ (nullable instancetype)ephemeralKeyPair;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSString *publicKeyJWK;
@property (nonatomic, readonly) STDSEllipticCurvePoint *publicKeyCurvePoint;

/**
 Creates and returns a new secret key derived using Elliptic Curve Diffie-Hellman
 and the certificate's public key (return nil on failure).
 Per OpenSSL documentation: Never use a derived secret directly. Typically it is passed through some
 hash function to produce a key (e.g. pass the secret as the first argument to STDSCreateConcatKDFWithSHA256)
 */
- (nullable NSData *)createSharedSecretWithEllipticCurveKey:(STDSEllipticCurvePoint *)ecKey;
- (nullable NSData *)createSharedSecretWithCertificate:(STDSDirectoryServerCertificate *)certificate;

@end

NS_ASSUME_NONNULL_END
