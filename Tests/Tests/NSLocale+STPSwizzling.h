//
//  NSLocale+STPSwizzling.h
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/17/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLocale (STPSwizzling)

+ (void)stp_withLocaleAs:(NSLocale *)locale perform:(void (^)(void))block;

@end
