//
//  STPBECSDebitAccountNumberValidator.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPBECSDebitAccountNumberValidator.h"

#import "NSString+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPBECSDebitAccountNumberValidator

+ (NSRange)_accountNumberLengthRangeForBSBNumber:(nullable NSString *)bsbNumber {
    // For a few banks we know how many digits the account number *should* have,
    // but we still allow users to enter up to 9 digits just in case some bank
    // decides to add more digits on.
    NSString *firstTwo = [bsbNumber stp_safeSubstringToIndex:2];
    if ([firstTwo isEqualToString:@"00"]) {
        // Stripe
        return NSMakeRange(9, 0);
    } else if ([firstTwo isEqualToString:@"06"]) {
        // Commonwealth/CBA: 8 digits https://www.commbank.com.au/support.digital-banking.confirm-account-number-digits.html
        return NSMakeRange(8, 1);
    } else if ([firstTwo isEqualToString:@"03"] || [firstTwo isEqualToString:@"73"]) {
        // Westpac/WBC: 6 digits
        return NSMakeRange(6, 3);
    } else if ([firstTwo isEqualToString:@"01"]) {
        // ANZ: 9 digits https://www.anz.com.au/support/help/
        return NSMakeRange(9, 0);
    } else if ([firstTwo isEqualToString:@"08"]) {
        // NAB: 9 digits https://www.nab.com.au/business/accounts/business-accounts-online-application-help
        return NSMakeRange(9, 0);
    }else if ([firstTwo isEqualToString:@"80"]) {
        // Cuscal: 4 digits(?) https://groups.google.com/a/stripe.com/d/msg/au-becs-debits-archive/EERH5iITxQ4/Ksb84bV1AQAJ
        return NSMakeRange(4, 5);
    } else {
        // Default 5-9 digits
        return NSMakeRange(5, 4);
    }
}

+ (STPTextValidationState)validationStateForText:(NSString *)text
                                   withBSBNumber:(nullable NSString *)bsbNumber
                         completeOnMaxLengthOnly:(BOOL)completeOnMaxLengthOnly {
    NSString *numericText = [self sanitizedNumericStringForString:text];
    if (numericText.length == 0) {
        return STPTextValidationStateEmpty;
    } else {
        NSRange accountLengthRange = [self _accountNumberLengthRangeForBSBNumber:bsbNumber];
        if (numericText.length < accountLengthRange.location) {
            return STPTextValidationStateIncomplete;
        } else if (!completeOnMaxLengthOnly && (NSLocationInRange(numericText.length, accountLengthRange) || numericText.length == NSMaxRange(accountLengthRange))) {
            return STPTextValidationStateComplete;
        } else if (completeOnMaxLengthOnly && numericText.length == NSMaxRange(accountLengthRange)) {
            return STPTextValidationStateComplete;
        } else if (completeOnMaxLengthOnly && NSLocationInRange(numericText.length, accountLengthRange)) {
            return STPTextValidationStateIncomplete;
        } else {
            return STPTextValidationStateInvalid;
        }
    }
}

+ (nullable NSString *)formattedSantizedTextFromString:(NSString *)string withBSBNumber:(nullable NSString *)bsbNumber {
    NSRange accountLengthRange = [self _accountNumberLengthRangeForBSBNumber:bsbNumber];
    return [[self sanitizedNumericStringForString:string] stp_safeSubstringToIndex:NSMaxRange(accountLengthRange)];
}

@end

NS_ASSUME_NONNULL_END
