//
//  STDSEllipticCurvePoint.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSEllipticCurvePoint.h"

#import "NSDictionary+DecodingHelpers.h"
#import "NSString+JWEHelpers.h"
#import "STDSSecTypeUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSEllipticCurvePoint

- (nullable instancetype)initWithX:(NSData *)x y:(NSData *)y {
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _publicKey = STDSSecKeyRefFromCoordinates(x, y);
        if (_publicKey == NULL) {
            return nil;
        }
    }
    
    return self;
}

- (nullable instancetype)initWithKey:(SecKeyRef)key {
    self = [super init];
    if (self) {
        _publicKey = key;
        CFErrorRef error = NULL;
        NSData *keyData = (NSData *)CFBridgingRelease(SecKeyCopyExternalRepresentation(key, &error));
        if (keyData == nil) {
            return nil;
        }
        
        NSUInteger coordinateLength = (keyData.length - 1) / 2; // -1 because the first byte is formatting 0x04
        NSData *xData = [keyData subdataWithRange:NSMakeRange(1, coordinateLength)];
        NSData *yData = [keyData subdataWithRange:NSMakeRange(1 + coordinateLength, coordinateLength)];
        _x = xData;
        _y = yData;
    }
    
    return self;
}

- (nullable instancetype)initWithCertificateData:(NSData *)certificateData {
    SecCertificateRef certificate = STDSSecCertificateFromData(certificateData);
    if (certificateData != NULL) {
        SecKeyRef key = STDSSecCertificateCopyPublicKey(certificate);
        CFRelease(certificate);
        if (key != NULL) {
            return [self initWithKey:key];
        }
    }
    return nil;
}

- (nullable instancetype)initWithJWK:(NSDictionary *)jwk {
    NSString *kty = [jwk _stds_stringForKey:@"kty" validator:^BOOL(NSString * _Nonnull val) {
        return [val isEqualToString:@"EC"];
    } required:YES error:NULL];
    NSString *crv = [jwk _stds_stringForKey:@"crv" validator:^BOOL(NSString * _Nonnull val) {
        return [val isEqualToString:@"P-256"];
    } required:YES error:NULL];
    
    NSData *coordinateX = [[jwk _stds_stringForKey:@"x" required:YES error:NULL] _stds_base64URLDecodedData];
    NSData *coordinateY = [[jwk _stds_stringForKey:@"y" required:YES error:NULL] _stds_base64URLDecodedData];
    
    if (kty == nil          ||
        crv == nil          ||
        coordinateX == nil  ||
        coordinateY == nil
        ) {
        return nil;
    }
    return [self initWithX:coordinateX y:coordinateY];
}

@end

NS_ASSUME_NONNULL_END
