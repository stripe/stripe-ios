//
//  NSString+Stripe.m
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "NSString+Stripe.h"

@implementation NSString (Stripe)

- (NSString *)stp_safeSubstringToIndex:(NSUInteger)index {
    return [self substringToIndex:MIN(self.length, index)];
}

- (NSString *)stp_safeSubstringFromIndex:(NSUInteger)index {
    return (index > self.length) ? @"" : [self substringFromIndex:index];
}

- (NSString *)stp_reversedString {
    NSMutableString *mutableReversedString = [NSMutableString stringWithCapacity:self.length];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:(NSStringEnumerationOptions)(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                          usingBlock:^(NSString *substring, __unused NSRange substringRange, __unused NSRange enclosingRange, __unused BOOL *stop) {
        [mutableReversedString appendString:substring];
    }];
    return [mutableReversedString copy];
}

- (NSString *)stp_stringByRemovingSuffix:(NSString *)suffix {
    if (suffix != nil && [self hasSuffix:suffix]) {
        return [self stp_safeSubstringToIndex:self.length-suffix.length];
    } else {
        return [self copy];
    }
}

@end

void linkNSStringCategory(void){}
