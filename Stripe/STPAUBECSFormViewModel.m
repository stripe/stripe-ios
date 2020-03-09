//
//  STPAUBECSFormViewModel.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPAUBECSFormViewModel.h"

#import "STPBECSDebitAccountNumberValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPLocalizationUtils.h"
#import "STPNumericStringValidator.h"
#import "STPBSBNumberValidator.h"
#import "STPPaymentMethodAUBECSDebitParams.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPAUBECSFormViewModel

- (nullable STPPaymentMethodAUBECSDebitParams *)becsDebitParams {
    if (![self _areFieldsComplete:YES]) {
        return nil;
    }

    STPPaymentMethodAUBECSDebitParams *params = [[STPPaymentMethodAUBECSDebitParams alloc] init];
    params.bsbNumber = [STPBSBNumberValidator sanitizedNumericStringForString:self.bsbNumber];
    params.accountNumber = [STPBECSDebitAccountNumberValidator sanitizedNumericStringForString:self.accountNumber];

    return params;
}

- (nullable STPPaymentMethodParams *)paymentMethodParams {
    if (![self _areFieldsComplete:NO]) {
        return nil;
    }
    STPPaymentMethodAUBECSDebitParams *params = self.becsDebitParams;

    STPPaymentMethodBillingDetails *billing = [[STPPaymentMethodBillingDetails alloc] init];
    billing.name = self.name;
    billing.email = self.email;

    return [STPPaymentMethodParams paramsWithAUBECSDebit:params
                                          billingDetails:billing
                                                metadata:nil];

}

- (BOOL)_areFieldsComplete:(BOOL)becsFieldsOnly {
    NSArray<NSNumber *> *fieldNums = nil;
    if (becsFieldsOnly) {
        fieldNums =   @[
            @(STPAUBECSFormViewFieldBSBNumber),
            @(STPAUBECSFormViewFieldAccountNumber),
        ];
    } else {
        fieldNums = @[
            @(STPAUBECSFormViewFieldName),
            @(STPAUBECSFormViewFieldEmail),
            @(STPAUBECSFormViewFieldBSBNumber),
            @(STPAUBECSFormViewFieldAccountNumber),
        ];
    }

    for (NSNumber *fieldNumber in fieldNums) {
        NSString *input = nil;
        STPAUBECSFormViewField field = (STPAUBECSFormViewField)[fieldNumber unsignedIntValue];
        switch (field) {
            case STPAUBECSFormViewFieldName:
                input = self.name;
                break;

            case STPAUBECSFormViewFieldEmail:
                input = self.email;
                break;

            case STPAUBECSFormViewFieldBSBNumber:
                input = self.bsbNumber;
                break;

            case STPAUBECSFormViewFieldAccountNumber:
                input = self.accountNumber;
                break;
        }

        if (![self isFieldCompleteWithInput:input inField:field editing:NO]) {
            return NO;
        }
    }

    return YES;
}


- (NSString *)formattedStringForInput:(NSString *)input inField:(STPAUBECSFormViewField)field {
    switch (field) {
        case STPAUBECSFormViewFieldName:
            return [input copy];
        case STPAUBECSFormViewFieldEmail:
            return [input copy];
        case STPAUBECSFormViewFieldBSBNumber:
            return [STPBSBNumberValidator formattedSantizedTextFromString:input];
        case STPAUBECSFormViewFieldAccountNumber:
            return [STPBECSDebitAccountNumberValidator formattedSantizedTextFromString:input withBSBNumber:[STPBSBNumberValidator sanitizedNumericStringForString:self.bsbNumber]];
    }
}

- (nullable NSString *)bsbLabelForInput:(nullable NSString *)input editing:(BOOL)editing isErrorString:(out BOOL *)isErrorString {
    STPTextValidationState state = [STPBSBNumberValidator validationStateForText:input];
    if (state == STPTextValidationStateInvalid) {
        *isErrorString = YES;
        return STPLocalizedString(@"The BSB you entered is invalid.", @"Error string displayed to user when they enter in an invalid BSB number.");
    } else if (state == STPTextValidationStateIncomplete && !editing) {
        *isErrorString = YES;
        return STPLocalizedString(@"The BSB you entered is incomplete.", @"Error string displayed to user when they have entered an incomplete BSB number.");
    } else {
        *isErrorString = NO;
        return [STPBSBNumberValidator identityForText:input];
    }
}

- (UIImage *)bankIconForInput:(nullable NSString *)input {
    return [STPBSBNumberValidator iconForText:input];
}

- (BOOL)isFieldCompleteWithInput:(NSString *)input inField:(STPAUBECSFormViewField)field editing:(BOOL)editing {
    switch (field) {
        case STPAUBECSFormViewFieldName:
            return input.length > 0;
        case STPAUBECSFormViewFieldEmail:
            return [STPEmailAddressValidator stringIsValidEmailAddress:input];
        case STPAUBECSFormViewFieldBSBNumber:
            return [STPBSBNumberValidator validationStateForText:input] == STPTextValidationStateComplete;
        case STPAUBECSFormViewFieldAccountNumber:
            // If it's currently being edited, we won't consider the account number field complete until it reaches its
            // maximum allowed length
            return [STPBECSDebitAccountNumberValidator validationStateForText:input withBSBNumber:[STPBSBNumberValidator sanitizedNumericStringForString:self.bsbNumber] completeOnMaxLengthOnly:editing] == STPTextValidationStateComplete;
    }
}

- (BOOL)isInputValid:(NSString *)input forField:(STPAUBECSFormViewField)field editing:(BOOL)editing {
    switch (field) {
        case STPAUBECSFormViewFieldName:
            return YES;
        case STPAUBECSFormViewFieldEmail:
            return input.length == 0 ||
            (editing && [STPEmailAddressValidator stringIsValidPartialEmailAddress:input]) ||
            (!editing && [STPEmailAddressValidator stringIsValidEmailAddress:input]);
        case STPAUBECSFormViewFieldBSBNumber: {
            STPTextValidationState state = [STPBSBNumberValidator validationStateForText:input];
            if (editing) {
                return state != STPTextValidationStateInvalid;
            } else {
                return state != STPTextValidationStateInvalid && state != STPTextValidationStateIncomplete;
            }
        }
        case STPAUBECSFormViewFieldAccountNumber: {
            STPTextValidationState state =  [STPBECSDebitAccountNumberValidator validationStateForText:input withBSBNumber:[STPBSBNumberValidator sanitizedNumericStringForString:self.bsbNumber] completeOnMaxLengthOnly:editing];
            if (editing) {
                return state != STPTextValidationStateInvalid;
            } else {
                return state != STPTextValidationStateInvalid && state != STPTextValidationStateIncomplete;
            }
        }
    }
}


@end

NS_ASSUME_NONNULL_END
