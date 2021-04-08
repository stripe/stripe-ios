//
//  STDSSecTypeUtilities.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSDirectoryServer.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns the SecCertificateRef for the specified server or NULL if there's an error
SecCertificateRef _Nullable STDSCertificateForServer(STDSDirectoryServer server);

/// Returns the public key in the certificate or NULL if there's an error
SecKeyRef _Nullable STDSSecCertificateCopyPublicKey(SecCertificateRef certificate);

/// Returns one of the values defined for kSecAttrKeyType in <Security/SecItem.h> or NULL
CFStringRef _Nullable STDSSecCertificateCopyPublicKeyType(SecCertificateRef certificate);

/// Returns the hashed secret or nil
NSData * _Nullable STDSCreateConcatKDFWithSHA256(NSData *sharedSecret, NSUInteger keyLength, NSString *apv);

/// Verifies the signature and payload using the Elliptic Curve P-256 with coordinateX and coordinateY
BOOL STDSVerifyEllipticCurveP256Signature(NSData *coordinateX, NSData *coordinateY, NSData *payload, NSData *signature);

/// Verifies the signature and payload using RSA-PSS
BOOL STDSVerifyRSASignature(SecCertificateRef certificate, NSData *payload, NSData *signature);

/// Returns data of length numBytes generated using CommonCrypto's CCRandomGenerateBytes or nil on failure
NSData * _Nullable STDSCryptoRandomData(size_t numBytes);

/// Creates a certificate from base64encoded data
SecCertificateRef _Nullable STDSSecCertificateFromData(NSData *data);

/// Creates a certificate from a PEM or DER encoded certificate string
SecCertificateRef _Nullable STDSSecCertificateFromString(NSString *certificateString);

// Creates a public key using Elliptic Curve P-256 with coordinateX and coordinateY
SecKeyRef _Nullable STDSSecKeyRefFromCoordinates(NSData *coordinateX, NSData *coordinateY);

// Creates a private key using Elliptic Curve P-256 with x, y, and d
SecKeyRef _Nullable STDSPrivateSecKeyRefFromCoordinates(NSData *x, NSData *y, NSData *d);


NS_ASSUME_NONNULL_END
