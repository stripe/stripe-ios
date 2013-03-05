//
//  CardNumber.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCardNumber.h"

@interface PKCardNumber() {
@private
    NSString* number;
}
@end

@implementation PKCardNumber

+ (id)cardNumberWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        // Strip non-digits
        number = [string stringByReplacingOccurrencesOfString:@"\\D"
                                                    withString:@""
                                                       options:NSRegularExpressionSearch
                                                         range:NSMakeRange(0, string.length)];
    }
    return self;
}

- (PKCardType)cardType
{    
    if (number.length < 2) return PKCardTypeUnknown;
    
    NSString* firstChars = [number substringWithRange:NSMakeRange(0, 2)];
    
    int range = [firstChars integerValue];
    
    if (range >= 40 && range <= 49) {
        return PKCardTypeVisa;
    } else if (range >= 50 && range <= 59) {
        return PKCardTypeMasterCard;
    } else if (range == 34 || range == 37) {
        return PKCardTypeAmex;
    } else if (range == 60 || range == 62 || range == 64 || range == 65) {
        return PKCardTypeDiscover;
    } else if (range == 35) {
        return PKCardTypeJCB;
    } else if (range == 30 || range == 36 || range == 38 || range == 39) {
        return PKCardTypeDinersClub;
    } else {
        return PKCardTypeUnknown;
    }
}

- (NSString *)last4
{
    if (number.length >= 4) {
        return [number substringFromIndex:([number length] - 4)];
    } else {
        return nil;
    }
}

- (NSString *)lastGroup
{
    if (self.cardType == PKCardTypeAmex) {
        if (number.length >= 5) {
            return [number substringFromIndex:([number length] - 5)];
        }
    } else {
        if (number.length >= 4) {
            return [number substringFromIndex:([number length] - 4)];
        }
    }
    
    return nil;
}


- (NSString *)string
{
    return number;
}

- (NSString *)formattedString
{
    NSRegularExpression* regex;
    
    if ([self cardType] == PKCardTypeAmex) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})(\\d{1,6})?(\\d{1,5})?" options:0 error:NULL];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})" options:0 error:NULL];
    }
    
    NSArray* matches = [regex matchesInString:number options:0 range:NSMakeRange(0, number.length)];
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:matches.count];
    
    for (NSTextCheckingResult *match in matches) {
        for (int i=1; i < [match numberOfRanges]; i++) {
            NSRange range = [match rangeAtIndex:i];
            
            if (range.length > 0) {
                NSString* matchText = [number substringWithRange:range];
                [result addObject:matchText];
            }
        }
    }
    
    return [result componentsJoinedByString:@" "];
}

- (NSString *)formattedStringWithTrail
{
    NSString *string = [self formattedString];
    NSRegularExpression* regex;
    
    // No trailing space needed
    if ([self isValidLength]) {
        return string;
    }

    if ([self cardType] == PKCardTypeAmex) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{4}|\\d{4}\\s\\d{6})$" options:0 error:NULL];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(?:^|\\s)(\\d{4})$" options:0 error:NULL];
    }
    
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    if (numberOfMatches == 0) {
        // Not at the end of a group of digits
        return string;
    } else {
        return [NSString stringWithFormat:@"%@ ", string];
    }
}

- (BOOL)isValid
{
    return [self isValidLength] && [self isValidLuhn];
}

- (BOOL)isValidLength
{
    if (self.cardType == PKCardTypeAmex) {
        return number.length == 15;
    } else {
        return number.length == 16;
    }
}

- (BOOL)isValidLuhn
{
    BOOL odd = true;
    int sum  = 0;
    NSMutableArray* digits = [NSMutableArray arrayWithCapacity:number.length];
    
    for (int i=0; i < number.length; i++) {
        [digits addObject:[number substringWithRange:NSMakeRange(i, 1)]];
    }
    
    for (NSString* digitStr in [digits reverseObjectEnumerator]) {
        int digit = [digitStr intValue];
        if ((odd = !odd)) digit *= 2;
        if (digit > 9) digit -= 9;
        sum += digit;
    }
    
    return sum % 10 == 0;
}

- (BOOL)isPartiallyValid
{
    if (self.cardType == PKCardTypeAmex) {
        return number.length <= 15;
    } else {
        return number.length <= 16;
    }
}

@end
