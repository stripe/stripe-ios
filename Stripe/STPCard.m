//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "StripeError.h"

@interface STPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) STPCardBrand brand;
@property (nonatomic, readwrite) STPCardFundingType funding;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic, readwrite) NSString *country;

@end

@implementation STPCard

- (instancetype)init {
    self = [super init];
    if (self) {
        _brand = STPCardBrandUnknown;
        _funding = STPCardFundingTypeOther;
    }

    return self;
}

- (NSString *)last4 {
    if (_last4) {
        return _last4;
    } else if (self.number && self.number.length >= 4) {
        return [self.number substringFromIndex:(self.number.length - 4)];
    } else {
        return nil;
    }
}

- (STPCardBrand)brand {
    if (_brand == STPCardBrandUnknown) {
        return [self.class cardTypeFromNumber:self.number];
    }
    return _brand;
}

- (NSString *)type {
    switch (self.brand) {
    case STPCardBrandAmex:
        return @"American Express";
    case STPCardBrandDinersClub:
        return @"Diners Club";
    case STPCardBrandDiscover:
        return @"Discover";
    case STPCardBrandJCB:
        return @"JCB";
    case STPCardBrandMasterCard:
        return @"MasterCard";
    case STPCardBrandVisa:
        return @"Visa";
    default:
        return @"Unknown";
    }
}

- (BOOL)validateNumber:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }

    NSString *ioValueString = (NSString *)*ioValue;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[\\s+|-]" options:NSRegularExpressionCaseInsensitive error:NULL];

    NSString *rawNumber = [regex stringByReplacingMatchesInString:ioValueString options:0 range:NSMakeRange(0, [ioValueString length]) withTemplate:@""];

    if (rawNumber == nil || rawNumber.length < 10 || rawNumber.length > 19 || ![STPCard isLuhnValidString:rawNumber]) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }
    return YES;
}

- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *cvc = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL validCvcLength = ({
        BOOL valid;
        switch (self.brand) {
        case STPCardBrandAmex:
        case STPCardBrandUnknown:
            valid = (cvc.length == 3 || cvc.length == 4);
            break;
        default:
            valid = (cvc.length == 3);
            break;
        }
        valid;
    });

    if (![STPCard isNumericOnlyString:cvc] || !validCvcLength) {
        return [STPCard handleValidationErrorForParameter:@"cvc" error:outError];
    }
    return YES;
}

- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }

    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expMonthInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expMonthInt > 12 || expMonthInt < 1)) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    } else if ([self expYear] && [STPCard isExpiredMonth:expMonthInt andYear:[self expYear] atDate:[NSDate date]]) {
        NSUInteger currentYear = [STPCard currentYear];
        // If the year is in the past, this is actually a problem with the expYear parameter, but it still means this month is not a valid month. This is pretty
        // rare - it means someone set expYear on the card without validating it
        if (currentYear > [self expYear]) {
            return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
        } else {
            return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
        }
    }
    return YES;
}

- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
    }

    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger expYearInt = [ioValueString integerValue];

    if ((![STPCard isNumericOnlyString:ioValueString] || expYearInt < [STPCard currentYear])) {
        return [STPCard handleValidationErrorForParameter:@"expYear" error:outError];
    } else if ([self expMonth] && [STPCard isExpiredMonth:[self expMonth] andYear:expYearInt atDate:[NSDate date]]) {
        return [STPCard handleValidationErrorForParameter:@"expMonth" error:outError];
    }

    return YES;
}

- (BOOL)validateCardReturningError:(NSError **)outError {
    // Order matters here
    NSString *numberRef = [self number];
    NSString *expMonthRef = [NSString stringWithFormat:@"%lu", (unsigned long)[self expMonth]];
    NSString *expYearRef = [NSString stringWithFormat:@"%lu", (unsigned long)[self expYear]];
    NSString *cvcRef = [self cvc];

    // Make sure expMonth, expYear, and number are set.  Validate CVC if it is provided
    return [self validateNumber:&numberRef error:outError] && [self validateExpYear:&expYearRef error:outError] &&
           [self validateExpMonth:&expMonthRef error:outError] && (cvcRef == nil || [self validateCvc:&cvcRef error:outError]);
}

- (BOOL)isEqual:(id)other {
    return [self isEqualToCard:other];
}

- (NSUInteger)hash {
    return [self.fingerprint hash] ?: [self.number hash];
}

- (BOOL)isEqualToCard:(STPCard *)other {
    if (self == other) {
        return YES;
    }

    if (!other || ![other isKindOfClass:self.class]) {
        return NO;
    }

    return self.expMonth == other.expMonth && self.expYear == other.expYear && [self.number ?: @"" isEqualToString:other.number ?: @""] &&
           [self.cvc ?: @"" isEqualToString:other.cvc ?: @""] && [self.name ?: @"" isEqualToString:other.name ?: @""] &&
           [self.addressLine1 ?: @"" isEqualToString:other.addressLine1 ?: @""] && [self.addressLine2 ?: @"" isEqualToString:other.addressLine2 ?: @""] &&
           [self.addressCity ?: @"" isEqualToString:other.addressCity ?: @""] && [self.addressState ?: @"" isEqualToString:other.addressState ?: @""] &&
           [self.addressZip ?: @"" isEqualToString:other.addressZip ?: @""] && [self.addressCountry ?: @"" isEqualToString:other.addressCountry ?: @""];
}

#pragma mark Private Helpers
+ (BOOL)isLuhnValidString:(NSString *)number {
    BOOL isOdd = true;
    NSInteger sum = 0;

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    for (NSInteger index = [number length] - 1; index >= 0; index--) {
        NSString *digit = [number substringWithRange:NSMakeRange(index, 1)];
        NSNumber *digitNumber = [numberFormatter numberFromString:digit];

        if (digitNumber == nil) {
            return NO;
        }

        NSInteger digitInteger = [digitNumber intValue];
        isOdd = !isOdd;
        if (isOdd) {
            digitInteger *= 2;
        }

        if (digitInteger > 9) {
            digitInteger -= 9;
        }

        sum += digitInteger;
    }

    return sum % 10 == 0;
}

+ (BOOL)isNumericOnlyString:(NSString *)aString {
    NSCharacterSet *numericOnly = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *aStringSet = [NSCharacterSet characterSetWithCharactersInString:aString];

    return [numericOnly isSupersetOfSet:aStringSet];
}

+ (NSCalendar *)gregorianCalendar {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wunreachable-code"
    NSString *identifier = (&NSCalendarIdentifierGregorian != nil) ? NSCalendarIdentifierGregorian : NSGregorianCalendar;
#pragma clang diagnostic pop
    return [[NSCalendar alloc] initWithCalendarIdentifier:identifier];
}

+ (BOOL)isExpiredMonth:(NSInteger)month andYear:(NSInteger)year atDate:(NSDate *)date {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    // Cards expire at end of month
    [components setMonth:month + 1];
    [components setDay:1];
    NSDate *expiryDate = [[self gregorianCalendar] dateFromComponents:components];
    return ([expiryDate compare:date] == NSOrderedAscending);
}

+ (NSInteger)currentYear {
    NSDateComponents *components = [[self gregorianCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
    return [components year];
}

+ (BOOL)handleValidationErrorForParameter:(NSString *)parameter error:(NSError **)outError {
    if (outError != nil) {
        if ([parameter isEqualToString:@"number"]) {
            *outError = [self createErrorWithMessage:STPCardErrorInvalidNumberUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidNumber
                                     devErrorMessage:@"Card number must be between 10 and 19 digits long and Luhn valid."];
        } else if ([parameter isEqualToString:@"cvc"]) {
            *outError = [self createErrorWithMessage:STPCardErrorInvalidCVCUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidCVC
                                     devErrorMessage:@"Card CVC must be numeric, 3 digits for Visa, Discover, MasterCard, JCB, and Discover cards, and 3 or 4 "
                                     @"digits for American Express cards."];
        } else if ([parameter isEqualToString:@"expMonth"]) {
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpMonthUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidExpMonth
                                     devErrorMessage:@"expMonth must be less than 13"];
        } else if ([parameter isEqualToString:@"expYear"]) {
            *outError = [self createErrorWithMessage:STPCardErrorInvalidExpYearUserMessage
                                           parameter:parameter
                                       cardErrorCode:STPInvalidExpYear
                                     devErrorMessage:@"expYear must be this year or a year in the future"];
        } else {
            // This should not be possible since this is a private method so we
            // know exactly how it is called.  We use STPAPIError for all errors
            // that are unexpected within the bindings as well.
            *outError = [[NSError alloc] initWithDomain:StripeDomain
                                                   code:STPAPIError
                                               userInfo:@{
                                                   NSLocalizedDescriptionKey: STPUnexpectedError,
                                                   STPErrorMessageKey: @"There was an error within the Stripe client library when trying to generate the "
                                                   @"proper validation error. Contact support@stripe.com if you see this."
                                               }];
        }
    }
    return NO;
}

+ (NSError *)createErrorWithMessage:(NSString *)userMessage
                          parameter:(NSString *)parameter
                      cardErrorCode:(NSString *)cardErrorCode
                    devErrorMessage:(NSString *)devMessage {
    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:STPCardError
                                  userInfo:@{
                                      NSLocalizedDescriptionKey: userMessage,
                                      STPErrorParameterKey: parameter,
                                      STPCardErrorCodeKey: cardErrorCode,
                                      STPErrorMessageKey: devMessage
                                  }];
}

+ (STPCardBrand)cardTypeFromNumber:(NSString *)number {
    if ([number hasPrefix:@"34"] || [number hasPrefix:@"37"]) {
        return STPCardBrandAmex;
    } else if ([number hasPrefix:@"60"] || [number hasPrefix:@"62"] || [number hasPrefix:@"64"] || [number hasPrefix:@"65"]) {
        return STPCardBrandDiscover;
    } else if ([number hasPrefix:@"35"]) {
        return STPCardBrandJCB;
    } else if ([number hasPrefix:@"30"] || [number hasPrefix:@"36"] || [number hasPrefix:@"38"] || [number hasPrefix:@"39"]) {
        return STPCardBrandDinersClub;
    } else if ([number hasPrefix:@"4"]) {
        return STPCardBrandVisa;
    } else if ([number hasPrefix:@"5"]) {
        return STPCardBrandMasterCard;
    } else {
        return STPCardBrandUnknown;
    }
}

@end


@implementation STPCard(PrivateMethods)

- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary {
    self = [self init];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [attributeDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj != [NSNull null]) {
            dict[key] = obj;
        }
    }];
    
    if (self) {
        _cardId = dict[@"id"];
        _number = dict[@"number"];
        _cvc = dict[@"cvc"];
        _name = dict[@"name"];
        _last4 = dict[@"last4"];
        NSString *brand = dict[@"brand"] ?: dict[@"type"];
        if ([brand isEqualToString:@"Visa"]) {
            _brand = STPCardBrandVisa;
        } else if ([brand isEqualToString:@"American Express"]) {
            _brand = STPCardBrandAmex;
        } else if ([brand isEqualToString:@"MasterCard"]) {
            _brand = STPCardBrandMasterCard;
        } else if ([brand isEqualToString:@"Discover"]) {
            _brand = STPCardBrandDiscover;
        } else if ([brand isEqualToString:@"JCB"]) {
            _brand = STPCardBrandJCB;
        } else if ([brand isEqualToString:@"Diners Club"]) {
            _brand = STPCardBrandDinersClub;
        } else {
            _brand = STPCardBrandUnknown;
        }
        NSString *funding = dict[@"funding"];
        if ([funding.lowercaseString isEqualToString:@"credit"]) {
            _funding = STPCardFundingTypeCredit;
        } else if ([funding.lowercaseString isEqualToString:@"debit"]) {
            _funding = STPCardFundingTypeDebit;
        } else if ([funding.lowercaseString isEqualToString:@"prepaid"]) {
            _funding = STPCardFundingTypePrepaid;
        } else {
            _funding = STPCardFundingTypeOther;
        }
        _fingerprint = dict[@"fingerprint"];
        _country = dict[@"country"];
        // Support both camelCase and snake_case keys
        _expMonth = [(dict[@"exp_month"] ?: dict[@"expMonth"])intValue];
        _expYear = [(dict[@"exp_year"] ?: dict[@"expYear"])intValue];
        _addressLine1 = dict[@"address_line1"] ?: dict[@"addressLine1"];
        _addressLine2 = dict[@"address_line2"] ?: dict[@"addressLine2"];
        _addressCity = dict[@"address_city"] ?: dict[@"addressCity"];
        _addressState = dict[@"address_state"] ?: dict[@"addressState"];
        _addressZip = dict[@"address_zip"] ?: dict[@"addressZip"];
        _addressCountry = dict[@"address_country"] ?: dict[@"addressCountry"];
    }
    
    return self;
}

@end


