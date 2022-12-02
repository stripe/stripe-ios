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
    Class class = object_getClass((id)self);
    Method originalMethod = class_getClassMethod(self, original);
    Method replacementMethod = class_getClassMethod(self, replacement);
    
    BOOL addedMethod = class_addMethod(class,
                                       original,
                                       method_getImplementation(replacementMethod),
                                       method_getTypeEncoding(replacementMethod));
    if (addedMethod) {
        class_replaceMethod(class,
                            replacement,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

@end

@implementation NSLocale (STPSwizzling)

static NSLocale *_stpLocaleOverride = nil;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self stp_swizzleClassMethod:@selector(currentLocale) withReplacement:@selector(stp_currentLocale)];
        [self stp_swizzleClassMethod:@selector(autoupdatingCurrentLocale) withReplacement:@selector(stp_autoUpdatingCurrentLocale)];
        [self stp_swizzleClassMethod:@selector(systemLocale) withReplacement:@selector(stp_systemLocale)];
    });
    
}

+ (void)stp_withLocaleAs:(NSLocale *)locale perform:(void (^)(void))block {
    NSLocale *currentLocale = NSLocale.currentLocale;
    [self stp_setCurrentLocale:locale];
    block();
    [self stp_resetCurrentLocale];
    NSAssert([currentLocale isEqual:NSLocale.currentLocale], @"Failed to reset locale.");
}

+ (void)stp_setCurrentLocale:(NSLocale *)locale
{
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
