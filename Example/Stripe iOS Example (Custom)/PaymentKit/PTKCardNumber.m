//
//  CardNumber.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCardNumber.h"

@implementation PTKCardNumber {
@private
    NSString *_number;
}

+ (instancetype)cardNumberWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string
{
   if (self = [super init]) {
        // Strip non-digits
        _number = [string stringByReplacingOccurrencesOfString:@"\\D"
                                                    withString:@""
                                                       options:NSRegularExpressionSearch
                                                         range:NSMakeRange(0, string.length)];
    }
    return self;
}

- (PTKCardType)cardType
{
    if (_number.length < 2) {
        return PTKCardTypeUnknown;
    }

    NSString *firstChars = [_number substringWithRange:NSMakeRange(0, 2)];
    NSInteger range = [firstChars integerValue];

    if (range >= 40 && range <= 49) {
        return PTKCardTypeVisa;
    } else if (range >= 50 && range <= 59) {
        return PTKCardTypeMasterCard;
    } else if (range == 34 || range == 37) {
        return PTKCardTypeAmex;
    } else if (range == 60 || range == 62 || range == 64 || range == 65) {
        return PTKCardTypeDiscover;
    } else if (range == 35) {
        return PTKCardTypeJCB;
    } else if (range == 30 || range == 36 || range == 38 || range == 39) {
        return PTKCardTypeDinersClub;
    } else {
        return PTKCardTypeUnknown;
    }
}

- (NSString *)last4
{
    if (_number.length >= 4) {
        return [_number substringFromIndex:([_number length] - 4)];
    } else {
        return nil;
    }
}

- (NSString *)lastGroup
{
    if (self.cardType == PTKCardTypeAmex) {
        if (_number.length >= 5) {
            return [_number substringFromIndex:([_number length] - 5)];
        }
    } else {
        if (_number.length >= 4) {
            return [_number substringFromIndex:([_number length] - 4)];
        }
    }

    return nil;
}


- (NSString *)string
{
    return _number;
}

- (NSString *)formattedString
{
    NSRegularExpression *regex;

    if (self.cardType == PTKCardTypeAmex) {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})(\\d{1,6})?(\\d{1,5})?" options:0 error:NULL];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,4})" options:0 error:NULL];
    }

    NSArray *matches = [regex matchesInString:_number options:0 range:NSMakeRange(0, _number.length)];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:matches.count];

    for (NSTextCheckingResult *match in matches) {
        for (int i = 1; i < [match numberOfRanges]; i++) {
            NSRange range = [match rangeAtIndex:i];

            if (range.length > 0) {
                NSString *matchText = [_number substringWithRange:range];
                [result addObject:matchText];
            }
        }
    }

    return [result componentsJoinedByString:@" "];
}

- (NSString *)formattedStringWithTrail
{
    NSString *string = [self formattedString];
    NSRegularExpression *regex;

    // No trailing space needed
    if ([self isValidLength]) {
        return string;
    }

    if (self.cardType == PTKCardTypeAmex) {
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
    return _number.length == [self lengthForCardType];
}

- (BOOL)isValidLuhn
{
    BOOL odd = true;
    int sum = 0;
    NSMutableArray *digits = [NSMutableArray arrayWithCapacity:_number.length];

    for (int i = 0; i < _number.length; i++) {
        [digits addObject:[_number substringWithRange:NSMakeRange(i, 1)]];
    }

    for (NSString *digitStr in [digits reverseObjectEnumerator]) {
        int digit = [digitStr intValue];
        if ((odd = !odd)) digit *= 2;
        if (digit > 9) digit -= 9;
        sum += digit;
    }

    return sum % 10 == 0;
}

- (BOOL)isPartiallyValid
{
    return _number.length <= [self lengthForCardType];
}

- (NSInteger)lengthForCardType
{
    PTKCardType type = self.cardType;
    NSInteger length;
    if (type == PTKCardTypeAmex) {
        length = 15;
    } else if (type == PTKCardTypeDinersClub) {
        length = 14;
    } else {
        length = 16;
    }
    return length;
}

@end
