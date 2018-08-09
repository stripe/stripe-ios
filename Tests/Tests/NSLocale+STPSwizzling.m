//
//  NSLocale+STPSwizzling.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/17/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "NSLocale+STPSwizzling.h"

#import <objc/runtime.h>

@interface NSObject (STPSwizzling)

+ (void)stp_swizzleClassMethod:(SEL)original withReplacement:(SEL)replacement;

@end

@implementation NSObject (STPSwizzling)

+ (void)stp_swizzleClassMethod:(SEL)original withReplacement:(SEL)replacement
{
    method_exchangeImplementations(class_getClassMethod(self, original), class_getClassMethod(self, replacement));
}

@end

@implementation NSLocale (STPSwizzling)

static NSLocale *_stpLocaleOverride = nil;

+ (void)stp_setCurrentLocale:(NSLocale *)locale
{
    if (_stpLocaleOverride == nil & locale != nil) {
        [self stp_swizzleClassMethod:@selector(currentLocale) withReplacement:@selector(stp_currentLocale)];
        [self stp_swizzleClassMethod:@selector(autoupdatingCurrentLocale) withReplacement:@selector(stp_autoUpdatingCurrentLocale)];
        [self stp_swizzleClassMethod:@selector(systemLocale) withReplacement:@selector(stp_systemLocale)];
    }
    _stpLocaleOverride = locale;
}

+ (void)stp_resetCurrentLocale
{
    [self stp_setCurrentLocale:nil];
}

+ (instancetype)stp_currentLocale {
    return _stpLocaleOverride ?: [self stp_currentLocale];
}

+ (instancetype)stp_autoUpdatingCurrentLocale {
    return _stpLocaleOverride ?: [self stp_autoUpdatingCurrentLocale];
}

+ (instancetype)stp_systemLocale {
    return _stpLocaleOverride ?: [self stp_systemLocale];
}

@end
