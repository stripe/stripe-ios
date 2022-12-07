//
//  NSData+JWEHelpers.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "NSData+JWEHelpers.h"

#import "NSString+JWEHelpers.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (STDSJSONWebEncryption)

- (nullable NSString *)_stds_base64URLEncodedString {
    // ref. https://tools.ietf.org/html/draft-ietf-jose-json-web-signature-41#appendix-C
    NSString *unpaddedBase64EncodedString = [[[[self base64EncodedStringWithOptions:0]
                                               stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]] // remove extra padding
                                              stringByReplacingOccurrencesOfString:@"+" withString:@"-"] // replace "+" character w/ "-"
                                             stringByReplacingOccurrencesOfString:@"/" withString:@"_"]; // replace "/" character w/ "_"
    
    return unpaddedBase64EncodedString;
}

- (nullable NSString *)_stds_base64URLDecodedString {
    return [[[self base64EncodedStringWithOptions:0]
             stringByReplacingOccurrencesOfString:@"-" withString:@"+"] // replace "-" character w/ "+"
            stringByReplacingOccurrencesOfString:@"_" withString:@"/"]; // replace "_" character w/ "/"
}

@end

NS_ASSUME_NONNULL_END

void _stds_import_nsdata_jwehelpers() {}
