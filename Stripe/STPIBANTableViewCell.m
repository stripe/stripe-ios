//
//  STPIBANTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 2/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPIBANTableViewCell.h"

#import "STPFormTextField.h"
#import "STPIBANValidator.h"
#import "STPLocalizationUtils.h"

@interface STPIBANTableViewCell()

@end

@implementation STPIBANTableViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
        self.textField.placeholder = STPLocalizedString(@"IBAN", @"IBAN placeholder – don't translate");
        self.textField.accessibilityLabel = self.textField.placeholder;
        self.textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorIBAN;
        self.textField.keyboardType = UIKeyboardTypeASCIICapable;
        self.textField.selectionEnabled = NO;
        self.textField.preservesContentsOnPaste = NO;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textValidationBlock = ^BOOL(NSString *text, BOOL editing) {
            if (editing) {
                return [STPIBANValidator stringIsValidPartialIBAN:text];
            } else {
                return [STPIBANValidator stringIsValidIBAN:text];
            }
        };
    }
    return self;
}

- (BOOL)isValid {
    return [STPIBANValidator stringIsValidIBAN:self.textField.text];
}

@end
