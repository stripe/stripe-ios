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

#if DEBUG
/**
 This overrides the bundle used to pull strings from to the specified lproj
 e.g. passing in @"fr" will use the strings in the "fr.lproj" directory
 inside the Stripe bundle.
 
 You can use this to override the language used by NSLocalizedString, however
 it is not recommend outside of debug environments.
 */
+ (void)overrideLanguageTo:(nullable NSString *)string;
#endif

@end

static inline NSString * _Nonnull STPLocalizedString(NSString* _Nonnull key, NSString * _Nullable __unused comment) {
    return [STPLocalizationUtils localizedStripeStringForKey:key];
}
