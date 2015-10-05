//
//  STPCardParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPCardParams.h"
#import "STPCardValidator.h"
#import "StripeError.h"

@implementation STPCardParams

- (NSString *)last4 {
    if (self.number && self.number.length >= 4) {
        return [self.number substringFromIndex:(self.number.length - 4)];
    } else {
        return nil;
    }
}

- (BOOL)isEqual:(id)other {
    return [self isEqualToCardParams:other];
}

- (NSUInteger)hash {
    return [self.number hash];
}

- (BOOL)isEqualToCardParams:(STPCardParams *)other {
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
    
    STPCardBrand brand = [STPCardValidator brandForNumber:self.number];
    
    if ([STPCardValidator validationStateForCVC:ioValueString cardBrand:brand] != STPCardValidationStateValid) {
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
