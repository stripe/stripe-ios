//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "StripeError.h"
#import "STPCardValidator.h"

@interface STPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *dynamicLast4;
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
        return [STPCardValidator brandForNumber:self.number];
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
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *ioValueString = (NSString *)*ioValue;
    
    if ([STPCardValidator validationStateForNumber:ioValueString validatingCardBrand:NO] != STPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    return YES;
}

- (BOOL)validateCvc:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"number" error:outError];
    }
    NSString *ioValueString = (NSString *)*ioValue;
    
    if ([STPCardValidator validationStateForCVC:ioValueString cardBrand:self.brand] != STPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"cvc" error:outError];
    }
    return YES;
}

- (BOOL)validateExpMonth:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([STPCardValidator validationStateForExpirationMonth:ioValueString] != STPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"expMonth" error:outError];
    }
    return YES;
}

- (BOOL)validateExpYear:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        return [self.class handleValidationErrorForParameter:@"expYear" error:outError];
    }
    NSString *ioValueString = [(NSString *)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *monthString = [@(self.expMonth) stringValue];
    if ([STPCardValidator validationStateForExpirationYear:ioValueString inMonth:monthString] != STPCardValidationStateValid) {
        return [self.class handleValidationErrorForParameter:@"expYear" error:outError];
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
    return [self.number hash];
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
        _dynamicLast4 = dict[@"dynamic_last4"];
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
        _currency = dict[@"currency"];
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


