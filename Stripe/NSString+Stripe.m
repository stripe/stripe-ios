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

- (NSString *)stp_safeSubstringWithRange:(NSRange)range {
    if (range.location + range.length > self.length) {
        return [self stp_safeSubstringFromIndex:range.location];
    }
    return [self substringWithRange:range];
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

- (NSString *)stp_stringByRemovingCharactersFromSet:(NSCharacterSet *)cs {
    NSString *string = [self copy];
    NSRange range = [string rangeOfCharacterFromSet:cs];
    if (range.location != NSNotFound) {
        NSMutableString *newString = [[string substringWithRange:NSMakeRange(0, range.location)] mutableCopy];
        NSUInteger lastPosition = NSMaxRange(range);
        while (lastPosition < string.length) {
            range = [string rangeOfCharacterFromSet:cs options:(NSStringCompareOptions)kNilOptions range:NSMakeRange(lastPosition, string.length - lastPosition)];
            if (range.location == NSNotFound) break;
            if (range.location != lastPosition) {
                [newString appendString:[string substringWithRange:NSMakeRange(lastPosition, range.location - lastPosition)]];
            }
            lastPosition = NSMaxRange(range);
        }
        if (lastPosition != string.length) {
            [newString appendString:[string substringWithRange:NSMakeRange(lastPosition, string.length - lastPosition)]];
        }
        return newString;
    } else {
        return string;
    }
}

@end

void linkNSStringCategory(void){}
