//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "StripeError.h"

@interface STPCard () {
    /*
     These two properties are not synthesized because they can be set by
     responses from the Stripe API or be dynamically generated from the number
     */
    NSString *last4;
    NSString *type;
}

+ (BOOL)isLuhnValidString:(NSString *)number;
+ (BOOL)isNumericOnlyString:(NSString *)aString;
+ (BOOL)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError;
+ (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter cardErrorCode:(NSString *)cardErrorCode devErrorMessage:(NSString *)devMessage;
+ (NSInteger)currentYear;
+ (BOOL)isExpiredMonth:(NSInteger)month andYear:(NSInteger)year;
@end


@implementation STPCard
@synthesize number, expMonth, expYear, cvc, name, addressLine1, addressLine2, addressZip, addressCity, addressState, addressCountry, country, object, fingerprint;
@dynamic last4, type;

#pragma mark Private Helpers
+ (BOOL)isLuhnValidString:(NSString *)number
{
    BOOL isOdd = true;
    NSInteger sum = 0;

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    for (NSInteger index = [number length] - 1; index >= 0; index--) {
        NSString *digit = [number substringWithRange:NSMakeRange(index, 1)];
        NSNumber *digitNumber = [numberFormatter numberFromString:digit];
        if (digitNumber == nil)
            return NO;
        NSInteger digitInteger = [digitNumber intValue];
        isOdd = !isOdd;
        if (isOdd)
            digitInteger *= 2;

        if (digitInteger > 9)
            digitInteger -= 9;

        sum += digitInteger;
    }

    if (sum % 10 == 0)
        return YES;
    else
        return NO;
}

+ (BOOL)isNumericOnlyString:(NSString *)aString
{
    NSCharacterSet *numericOnly = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *aStringSet = [NSCharacterSet characterSetWithCharactersInString:aString];

    return [numericOnly isSupersetOfSet:aStringSet];
}

+ (BOOL)isExpiredMonth:(NSInteger)month andYear:(NSInteger)year
{
    NSDate *now = [NSDate date];

    // Cards expire at end of month
    month = month + 1;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:1];
    NSDate *expiryDate = [calendar dateFromComponents:components];
    return ([expiryDate compare:now] == NSOrderedAscending);
}

+ (NSInteger)currentYear
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
    return [components year];
}

+ (BOOL)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError
{
    if (outError != nil) {
        if ([parameter isEqualToString:@"number"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidNumberUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidNumber
                                     devErrorMessage:@"Card number must be between 10 and 19 digits long and Luhn valid."];
        else if ([parameter isEqualToString:@"cvc"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidCVCUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidCVC
                                     devErrorMessage:@"Card CVC must be numeric, 3 digits for Visa, Discover, MasterCard, JCB, and Discover cards, and 4 digits for American Express cards."];
        else if ([parameter isEqualToString:@"expMonth"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpMonthUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidExpMonth
                                     devErrorMessage:@"expMonth must be less than 13"];
        else if ([parameter isEqualToString:@"expYear"])
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpYearUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidExpYear
                                     devErrorMessage:@"expYear must be this year or a year in the future"];
        else
                /* This should not be possible since this is a private method so we
                    know exactly how it is called.  We use STPAPIError for all errors
                    that are unexpected within the bindings as well.
                 */
            *outError = [[NSError alloc] initWithDomain:StripeDomain
                                                   code:STPAPIError
                                               userInfo:@{NSLocalizedDescriptionKey : STPUnexpectedError,
                                                       STPErrorMessageKey : @"There was an error within the Stripe client library when trying to generate the proper validation error. Contact support@stripe.com if you see this."}];
    }
    return NO;
}

+ (NSError *)createErrorWithMessage:(NSString *)userMessage parameter:(NSString *)parameter cardErrorCode:(NSString *)cardErrorCode devErrorMessage:(NSString *)devMessage
{
    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:STPCardError
                                  userInfo:@{
                                          NSLocalizedDescriptionKey : userMessage,
                                          STPErrorParameterKey : parameter,
                                          STPCardErrorCodeKey : cardErrorCode,
                                          STPErrorMessageKey : devMessage
                                  }];
}

#pragma mark Public Interface
- (id)init
{
    if (self = [super init])
        object = @"card";
    return self;
}

- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary
{
    if (self = [self init]) {
        number = [attributeDictionary valueForKey:@"number"];
        expMonth = [attributeDictionary[@"expMonth"] intValue];
        expYear = [attributeDictionary[@"expYear"] intValue];
        cvc = attributeDictionary[@"cvc"];
        name = attributeDictionary[@"name"];
        addressLine1 = attributeDictionary[@"addressLine1"];
        addressLine2 = attributeDictionary[@"addressLine2"];
        addressCity = attributeDictionary[@"addressCity"];
        addressState = attributeDictionary[@"addressState"];
        addressZip = attributeDictionary[@"addressZip"];
        addressCountry = attributeDictionary[@"addressCountry"];
        object = attributeDictionary[@"object"];
        last4 = attributeDictionary[@"last4"];
        type = attributeDictionary[@"type"];
        fingerprint = attributeDictionary[@"fingerprint"];
        country = attributeDictionary[@"country"];
    }
    return self;
}

- (NSString *)last4
{
    if (last4)
        return last4;
    else if ([self number])
        return [number substringFromIndex:([number length] - 4)];
    else
        return nil;
}

- (NSString *)type
{
    if (type)
        return type;
    else if ([self number]) {
        NSString *theNumber = [self number];
        if ([theNumber hasPrefix:@"34"] || [theNumber hasPrefix:@"37"])
            return @"American Express";
        else if ([theNumber hasPrefix:@"60"] ||
                [theNumber hasPrefix:@"62"] ||
                [theNumber hasPrefix:@"64"] ||
                [theNumber hasPrefix:@"65"])
            return @"Discover";
        else if ([theNumber hasPrefix:@"35"])
            return @"JCB";
        else if ([theNumber hasPrefix:@"30"] ||
                [theNumber hasPrefix:@"36"] ||
                [theNumber hasPrefix:@"38"] ||
                [theNumber hasPrefix:@"39"])
            return @"Diners Club";
        else if ([theNumber hasPrefix:@"4"])
            return @"Visa";
        else if ([theNumber hasPrefix:@"5"])
            return @"MasterCard";
        else
            return @"Unknown";
    }
    else
        return nil;
}

- (BOOL)validateNumber:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }

    NSError *regexError = nil;
    NSString *ioValueString = (NSString *) *ioValue;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[\\s+|-]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&regexError];

    NSString *rawNumber = [regex stringByReplacingMatchesInString:ioValueString options:0 range:NSMakeRange(0, [ioValueString length]) withTemplate:@""];

    if (rawNumber == nil || rawNumber.length < 10 || rawNumber.length > 19 || ![STPCard isLuhnValidString:rawNumber]) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }
    return YES;
}

- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *ioValueString = [(NSString *) *ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *cardType = [self type];
    BOOL validLength = ((cardType == nil && [ioValueString length] >= 3 && [ioValueString length] <= 4) ||
            ([cardType isEqualToString:@"American Express"] && [ioValueString length] == 4) ||
            (![cardType isEqualToString:@"American Express"] && [ioValueString length] == 3));


    if (![STPCard isNumericOnlyString:ioValueString] || !validLength) {
        return [STPCard handleValidationErrorForParameter:@"cvc" error:outError];
    }
    return YES;
}

- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    NSString *ioValueString = [(NSString *) *ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expMonthInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expMonthInt > 12 || expMonthInt < 1)) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    else if ([self expYear] && [STPCard isExpiredMonth:expMonthInt andYear:[self expYear]]) {
        NSInteger currentYear = [STPCard currentYear];
        // If the year is in the past, this is actually a problem with the expYear parameter, but it still means this month is not a valid month. This is pretty rare - it means someone set expYear on the card without validating it
        if (currentYear > [self expYear])
            return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
        else
            return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    return YES;
}

- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
    }

    NSString *ioValueString = [(NSString *) *ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expYearInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expYearInt < [STPCard currentYear])) {
        return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
    }
    else if ([self expMonth] && [STPCard isExpiredMonth:[self expMonth] andYear:expYearInt]) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }

    return YES;
}

- (BOOL)validateCardReturningError:(NSError **)outError;
{
    // Order matters here
    NSString *numberRef = [self number];
    NSString *expMonthRef = [NSString stringWithFormat:@"%lu", (unsigned long) [self expMonth]];
    NSString *expYearRef = [NSString stringWithFormat:@"%lu", (unsigned long) [self expYear]];
    NSString *cvcRef = [self cvc];

    // Make sure expMonth, expYear, and number are set.  Validate CVC if it is provided
    return [self validateNumber:&numberRef error:outError] &&
            [self validateExpYear:&expYearRef error:outError] &&
            [self validateExpMonth:&expMonthRef error:outError] &&
            (cvcRef == nil || [self validateCvc:&cvcRef error:outError]);
}
@end