//
//  NSError+Stripe3DS2.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "NSError+Stripe3DS2.h"
#import "STDSLocalizedString.h"

#import "STDSStripe3DS2Error.h"

@implementation NSError (Stripe3DS2)

+ (instancetype)_stds_invalidJSONFieldError:(NSString *)fieldName {
    return [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                               code:STDSErrorCodeJSONFieldInvalid
                           userInfo:@{STDSStripe3DS2ErrorFieldKey: fieldName}];
}

+ (instancetype)_stds_missingJSONFieldError:(NSString *)fieldName {
    return [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                               code:STDSErrorCodeJSONFieldMissing
                           userInfo:@{STDSStripe3DS2ErrorFieldKey: fieldName}];
}

+ (instancetype)_stds_timedOutError {
    return [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                               code:STDSErrorCodeTimeout
                           userInfo:@{NSLocalizedDescriptionKey : STDSLocalizedString(@"Timeout", @"Error description for when a network request times out. English value is as required by UL certification.")}];
}

+ (instancetype)_stds_jweError {
    return [[NSError alloc] initWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorCodeDecryptionVerification userInfo:nil];
}

@end
