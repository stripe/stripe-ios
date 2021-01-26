//
//  STDSEphemeralKeyPair.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSEphemeralKeyPair.h"

#import "NSData+JWEHelpers.h"
#import "NSDictionary+DecodingHelpers.h"
#import "NSString+JWEHelpers.h"
#import "STDSDirectoryServerCertificate.h"
#import "STDSEllipticCurvePoint.h"
#import "STDSSecTypeUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSEphemeralKeyPair ()
{
    SecKeyRef _privateKey;
    SecKeyRef _publicKey;
}

@end


@implementation STDSEphemeralKeyPair

- (instancetype)_initWithPrivateKey:(SecKeyRef)privateKey publicKey:(SecKeyRef)publicKey {
    self = [super init];
    if (self) {
        _privateKey = privateKey;
        _publicKey = publicKey;
    }
    
    return self;
}

+ (nullable instancetype)ephemeralKeyPair {
    NSDictionary *parameters = @{
        (__bridge NSString *)kSecAttrKeyType: (__bridge NSString *)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge NSString *)kSecAttrKeySizeInBits: @(256),
    };
    CFErrorRef error = NULL;
    SecKeyRef privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, &error);
    
    if (privateKey != NULL) {
        SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
        return [[self alloc] _initWithPrivateKey:privateKey publicKey:publicKey];
    }
    
    return nil;
}

+ (nullable instancetype)testKeyPair {
    
    // values from EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
    NSData *d = [@"iyn--IbkBeNoPu8cN245L6pOQWt2lTH8V0Ds92jQmWA" _stds_base64URLDecodedData];
    NSData *x = [@"C1PL42i6kmNkM61aupEAgLJ4gF1ZRzcV7lqo1TG0mL4" _stds_base64URLDecodedData];
    NSData *y = [@"cNToWLSdcFQKG--PGVEUQrIHP8w6TcRyj0pyFx4-ZMc" _stds_base64URLDecodedData];
    
    SecKeyRef privateKey = STDSPrivateSecKeyRefFromCoordinates(x, y, d);
    if (privateKey == NULL) {
        return nil;
    }
    SecKeyRef publicKey = SecKeyCopyPublicKey(privateKey);
    if (publicKey == NULL) {
        return nil;
    }
    
    return [[STDSEphemeralKeyPair alloc] _initWithPrivateKey:privateKey publicKey:publicKey];
}

- (void)dealloc {
    if (_privateKey != NULL) {
        CFRelease(_privateKey);
    }
    if (_publicKey != NULL) {
        CFRelease(_publicKey);
    }
}

- (NSString *)publicKeyJWK {
    STDSEllipticCurvePoint *publicKeyCurvePoint = [[STDSEllipticCurvePoint alloc] initWithKey:_publicKey];
    return [NSString stringWithFormat:@"{\"kty\":\"EC\",\"crv\":\"P-256\",\"x\":\"%@\",\"y\":\"%@\"}", [publicKeyCurvePoint.x _stds_base64URLEncodedString], [publicKeyCurvePoint.y _stds_base64URLEncodedString]];
}

- (nullable NSData *)createSharedSecretWithEllipticCurveKey:(STDSEllipticCurvePoint *)ecKey {
    return [self _createSharedSecretWithPrivateKey:_privateKey publicKey:ecKey.publicKey];
}

- (nullable NSData *)createSharedSecretWithCertificate:(STDSDirectoryServerCertificate *)certificate {
    return [self _createSharedSecretWithPrivateKey:_privateKey publicKey:certificate.publicKey];
}

- (nullable NSData *)_createSharedSecretWithPrivateKey:(SecKeyRef)privateKey publicKey:(SecKeyRef)publicKey {
    NSDictionary *params = @{(__bridge NSString *)kSecKeyKeyExchangeParameterRequestedSize: @(32)};
    CFErrorRef error = NULL;
    CFDataRef secret = SecKeyCopyKeyExchangeResult(privateKey, kSecKeyAlgorithmECDHKeyExchangeStandard, publicKey, (__bridge CFDictionaryRef)params, &error);
    
    return (NSData *)CFBridgingRelease(secret);
}

@end

NS_ASSUME_NONNULL_END
