//
//  NSLocale+STPSwizzling.h
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/17/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLocale (STPSwizzling)

+ (void)stp_setCurrentLocale:(NSLocale *)locale;
+ (void)stp_resetCurrentLocale;

@end
