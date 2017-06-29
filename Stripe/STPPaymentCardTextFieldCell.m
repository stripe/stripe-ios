//
//  STPPaymentCardTextFieldCell.m
//  Stripe
//
//  Created by Jack Flintermann on 6/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardTextFieldCell.h"

@interface STPPaymentCardTextFieldCell()

@property(nonatomic, weak)STPPaymentCardTextField *paymentField;

@end

@implementation STPPaymentCardTextFieldCell

- (instancetype)init {
    self = [super init];
    if (self) {
        STPPaymentCardTextField *paymentField = [[STPPaymentCardTextField alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:paymentField];
        _paymentField = paymentField;

        _theme = [STPTheme defaultTheme];
        [self updateAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.paymentField.frame = self.bounds;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.paymentField.backgroundColor = [UIColor clearColor];
    self.paymentField.placeholderColor = self.theme.tertiaryForegroundColor;
    self.paymentField.borderColor = [UIColor clearColor];
    self.paymentField.textColor = self.theme.primaryForegroundColor;
    self.paymentField.textErrorColor = self.theme.errorColor;
    self.paymentField.font = self.theme.font;
    self.backgroundColor = self.theme.secondaryBackgroundColor;
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    self.paymentField.inputAccessoryView = inputAccessoryView;
}

- (BOOL)isEmpty {
    return self.paymentField.cardNumber.length == 0;
}

- (BOOL)becomeFirstResponder {
    return [self.paymentField becomeFirstResponder];
}


@end
