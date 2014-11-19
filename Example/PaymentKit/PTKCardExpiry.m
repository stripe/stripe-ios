//
//  PTKCardExpiry.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCardExpiry.h"

@implementation PTKCardExpiry {
  @private
    NSString *_month;
    NSString *_year;
}

+ (instancetype)cardExpiryWithString:(NSString *)string {
    return [[self alloc] initWithString:string];
}

- (instancetype)initWithString:(NSString *)string {
    if (!string) {
        return [self initWithMonth:@"" year:@""];
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{1,2})?[\\s/]*(\\d{1,4})?" options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];

    NSString *monthStr = [NSString string];
    NSString *yearStr = [NSString string];

    if (match) {
        NSRange monthRange = [match rangeAtIndex:1];
        if (monthRange.length > 0) {
            monthStr = [string substringWithRange:monthRange];
        }

        NSRange yearRange = [match rangeAtIndex:2];
        if (yearRange.length > 0) {
            yearStr = [string substringWithRange:yearRange];
        }
    }

    return [self initWithMonth:monthStr year:yearStr];
}

- (instancetype)initWithMonth:(NSString *)monthStr year:(NSString *)yearStr {
    if (self = [super init]) {
        _month = monthStr;
        _year = yearStr;

        if (_month.length == 1) {
            if (!([_month isEqualToString:@"0"] || [_month isEqualToString:@"1"])) {
                _month = [NSString stringWithFormat:@"0%@", _month];
            }
        }
    }
    return self;
}

- (NSString *)formattedString {
    if (_year.length > 0)
        return [NSString stringWithFormat:@"%@/%@", _month, _year];

    return [NSString stringWithFormat:@"%@", _month];
}

- (NSString *)formattedStringWithTrail {
    if (_month.length == 2 && _year.length == 0) {
        return [NSString stringWithFormat:@"%@/", [self formattedString]];
    } else {
        return [self formattedString];
    }
}

- (BOOL)isValid {
    return [self isValidLength] && [self isValidDate];
}

- (BOOL)isValidLength {
    return _month.length == 2 && (_year.length == 2 || _year.length == 4);
}

- (BOOL)isValidDate {
    if ([self month] <= 0 || [self month] > 12)
        return NO;

    return [self isValidWithDate:[NSDate date]];
}

- (BOOL)isValidWithDate:(NSDate *)dateToCompare {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:dateToCompare];
    BOOL valid = NO;

    if (components.year < self.year) {
        valid = YES;
    } else if (components.year == self.year) {
        valid = components.month <= self.month;
    }
    return valid;
}

- (BOOL)isPartiallyValid {
    if ([self isValidLength]) {
        return [self isValidDate];
    } else {
        return [self month] <= 12 && _year.length <= 4;
    }
}

- (NSDate *)expiryDate {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    [components setMonth:[self month]];
    [components setYear:[self year]];

    static NSCalendar *gregorian = nil;
    if (!gregorian) {
        gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }

    // Move to the last day of the month.
    NSRange monthRange = [gregorian rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:[gregorian dateFromComponents:components]];

    [components setDay:monthRange.length];
    [components setHour:23];
    [components setMinute:59];

    return [gregorian dateFromComponents:components];
}

- (NSUInteger)month {
    return (NSUInteger)[_month integerValue];
}

- (NSUInteger)year {
    if (!_year) {
        return 0;
    }

    NSString *yearStr = [NSString stringWithString:_year];

    if (yearStr.length == 2) {
        static NSDateFormatter *formatter = nil;
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy"];
        }

        NSString *prefix = [formatter stringFromDate:[NSDate date]];
        prefix = [prefix substringWithRange:NSMakeRange(0, 2)];
        yearStr = [NSString stringWithFormat:@"%@%@", prefix, yearStr];
    }

    return (NSUInteger)[yearStr integerValue];
}

@end
