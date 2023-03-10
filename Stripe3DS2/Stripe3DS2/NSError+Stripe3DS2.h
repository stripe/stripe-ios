//
//  NSError+Stripe3DS2.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Stripe3DS2)


/// Represents an error where a JSON field value is not valid (e.g. expected 'Y' or 'N' but received something else).
+ (instancetype)_stds_invalidJSONFieldError:(NSString *)fieldName;

/// Represents an error where a JSON field was either required or conditionally required but missing, empty, or null.
+ (instancetype)_stds_missingJSONFieldError:(NSString *)fieldName;

/// Represents an error where a network request timed out.
+ (instancetype)_stds_timedOutError;

// We explicitly do not provide any more info here based on security recommendations
// "the recipient MUST NOT distinguish between format, padding, and length errors of encrypted keys"
// https://tools.ietf.org/html/rfc7516#section-11.5
+ (instancetype)_stds_jweError;

@end

NS_ASSUME_NONNULL_END
