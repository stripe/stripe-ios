//
//  STPLocalizationUtils.h
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPLocalizationUtils : NSObject

/**
 Acts like NSLocalizedString but tries to find the string in the Stripe
 bundle first if possible.
 */
+ (nonnull NSString *)localizedStripeStringForKey:(nonnull NSString *)key;

@end

static inline NSString * _Nonnull STPLocalizedString(NSString* _Nonnull key, NSString * _Nullable __unused comment) {
    return [STPLocalizationUtils localizedStripeStringForKey:key];
}

/// Use to explicitly ignore static analyzer warning: "User-facing text should use localized string macro"
__attribute__((annotate("returns_localized_nsstring")))
static inline NSString * _Nonnull STPNonLocalizedString(NSString * _Nonnull string) {
    return string;
}
