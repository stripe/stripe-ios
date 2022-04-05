//
//  STDSJSONWebSignature.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 4/2/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSJSONWebSignature.h"

#import "NSString+JWEHelpers.h"
#import "STDSEllipticCurvePoint.h"
#import "STDSSecTypeUtilities.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kJWSAlgorithmKey = @"alg";
static NSString * const kJWSAlgorithmES256 = @"ES256";
static NSString * const kJWSAlgorithmPS256 = @"PS256";

static NSString * const kJWSCertificateChainKey = @"x5c";

@implementation STDSJSONWebSignature

- (nullable instancetype)initWithString:(NSString *)jwsString {
    return [self initWithString:jwsString allowNilKey:NO];
}

- (nullable instancetype)initWithString:(NSString *)jwsString allowNilKey:(BOOL)allowNilKey {
    self = [super init];
    if (self) {
        NSArray<NSString *> *components = [jwsString componentsSeparatedByString:@"."];
        if (components.count != 3) {
            return nil;
        }
        NSData *headerData = [components[0] _stds_base64URLDecodedData];
        if (headerData == nil) {
            return nil;
        }
        NSError *jsonError = nil;
        NSDictionary * headerJSON = [NSJSONSerialization JSONObjectWithData:headerData options:0 error:&jsonError];
        if (headerJSON == nil) {
            return nil;
        }
        
        if (headerJSON[kJWSCertificateChainKey] != nil && ![headerJSON[kJWSCertificateChainKey] isKindOfClass:[NSArray class]]) {
            return nil;
        }
        
        _certificateChain = headerJSON[kJWSCertificateChainKey];

        NSString *algorithm = headerJSON[kJWSAlgorithmKey];
        if ([algorithm compare:kJWSAlgorithmES256 options: NSCaseInsensitiveSearch] == NSOrderedSame) {
            _algorithm = STDSJSONWebSignatureAlgorithmES256;
            if (_certificateChain.count > 0) {
                SecCertificateRef certificate = STDSSecCertificateFromString(_certificateChain.firstObject);
                if (certificate != NULL) {
                    SecKeyRef key = SecCertificateCopyKey(certificate);
                    CFRelease(certificate);
                    if (key != NULL) {
                        _ellipticCurvePoint = [[STDSEllipticCurvePoint alloc] initWithKey:key];
                        CFRelease(key);
                    }
                }
                if (_ellipticCurvePoint == nil && !allowNilKey) {
                    return nil;
                }
            } else if (!allowNilKey) {
                return nil;
            }

        } else if ([algorithm compare:kJWSAlgorithmPS256 options: NSCaseInsensitiveSearch] == NSOrderedSame) {
            _algorithm = STDSJSONWebSignatureAlgorithmPS256;
        } else {
            return nil;
        }

        _digest = [[@[components[0], components[1]] componentsJoinedByString:@"."] dataUsingEncoding:NSUTF8StringEncoding];
        _signature = [components[2] _stds_base64URLDecodedData];
        _payload = [components[1] _stds_base64URLDecodedData];
    }

    return self;
}

@end

NS_ASSUME_NONNULL_END
