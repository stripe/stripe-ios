//
//  STPLocalizedStringUtils.h
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STPLocalizedString(key, comment) \
[STPLocalizationUtils localizedStripeStringForKey:(key)]

@interface STPLocalizationUtils : NSObject

/**
 Acts like NSLocalizedString but tries to find the string in the Stripe
 bundle first if possible.
 */
+ (nonnull NSString *)localizedStripeStringForKey:(nonnull NSString *)key;

@end
