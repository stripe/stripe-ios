//
//  PKCardExpiry.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCardExpiry.h"

@interface PKCardExpiry () {
    @private
    NSString* month;
    NSString* year;
}
@end

@implementation PKCardExpiry

+ (id) cardExpiryWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (id) initWithString:(NSString *)string
{
    if ( !string ) {
        return [self initWithMonth:@"" andYear:@""];
    }
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{1,2})?[\\s/]*(\\d{1,4})?" options:0 error:NULL];

    NSTextCheckingResult* match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];

    NSString* monthStr = [NSString string];
    NSString* yearStr  = [NSString string];
    
    if (match) {
        NSRange monthRange = [match rangeAtIndex:1];
        if (monthRange.length > 0)
            monthStr = [string substringWithRange:monthRange];
        
        NSRange yearRange  = [match rangeAtIndex:2];
        if (yearRange.length > 0)
            yearStr = [string substringWithRange:yearRange];
    }
    
    return [self initWithMonth:monthStr andYear:yearStr];
}

- (id) initWithMonth:(NSString*)monthStr andYear:(NSString*)yearStr
{
    self = [super init];
    if (self) {
        month = monthStr;
        year  = yearStr;
        
        if (month.length == 1) {
            if ( !([month isEqualToString:@"0"] || [month isEqualToString:@"1"]) ){
                month = [NSString stringWithFormat:@"0%@", month];
            }
        }
    }
    return self;
}

- (NSString *)formattedString
{
    if (year.length > 0)
        return [NSString stringWithFormat:@"%@/%@", month, year];

    return [NSString stringWithFormat:@"%@", month];    
}

- (NSString *)formattedStringWithTrail
{
    if (month.length == 2 && year.length == 0) {
        return [NSString stringWithFormat:@"%@/", [self formattedString]];
    } else {
        return [self formattedString];
    }
}

- (BOOL)isValid
{
    return [self isValidLength] && [self isValidDate];
}

- (BOOL)isValidLength
{
    return month.length == 2 && (year.length == 2 || year.length == 4);
}

- (BOOL)isValidDate
{
    if ([self month] <= 0 || [self month] > 12) return false;
    
    NSDate* now = [NSDate date];
    return [[self expiryDate] compare:now] == NSOrderedDescending;
}

- (BOOL)isPartiallyValid
{
    if ([self isValidLength]) {
        return [self isValidDate];
    } else {
        return [self month] <= 12 && year.length <= 4;
    }
}

- (NSDate*)expiryDate
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];    
    [comps setMonth:[self month]];
    [comps setYear:[self year]];
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    return [gregorian dateFromComponents:comps];
}

- (NSUInteger)month
{
    if (!month) return 0;
    return [month integerValue];
}

- (NSUInteger)year
{
    if (!year) return 0;
    
    NSString* yearStr = [NSString stringWithString:year];
    
    if (yearStr.length == 2) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy"];
        NSString* prefix = [formatter stringFromDate:[NSDate date]];
        prefix = [prefix substringWithRange:NSMakeRange(0, 2)];
        yearStr = [NSString stringWithFormat:@"%@%@", prefix, yearStr];
    }
    
    return [yearStr integerValue];
}

@end
