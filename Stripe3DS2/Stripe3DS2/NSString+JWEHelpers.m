//
//  NSString+JWEHelpers.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "NSString+JWEHelpers.h"

#import "NSData+JWEHelpers.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSString (JWEHelpers)

- (nullable NSString *)_stds_base64URLEncodedString {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] _stds_base64URLEncodedString];
}

- (nullable NSString *)_stds_base64URLDecodedString {
    NSData *data = [self _stds_base64URLDecodedData];
    return data != nil ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

// ref. https://tools.ietf.org/html/draft-ietf-jose-json-web-signature-41#appendix-C
- (nullable NSData *)_stds_base64URLDecodedData {
    NSMutableString *decodedString = [[[self stringByReplacingOccurrencesOfString:@"-" withString:@"+"] // replace "-" character w/ "+"
                                       stringByReplacingOccurrencesOfString:@"_" withString:@"/"] mutableCopy]; // replace "_" character w/ "/"];

    switch (decodedString.length % 4) {
        case 0:
            break; // no padding needed
        case 2:
            [decodedString appendString:@"=="]; // pad with 2
            break;
        case 3:
            [decodedString appendString:@"="]; // pad with 1
            break;
        default:
            return nil; // invalid base64url string

    }

    return [[NSData alloc] initWithBase64EncodedString:decodedString options:0];
}

@end

NS_ASSUME_NONNULL_END

void _stds_import_nsstring_jwehelpers() {}
