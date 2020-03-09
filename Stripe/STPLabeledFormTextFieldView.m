//
//  STPLabeledFormTextFieldView.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPLabeledFormTextFieldView.h"

#import "STPFormTextField.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPLabeledFormTextFieldView {
    UILabel *_formLabel;
}

- (instancetype)initWithFormLabel:(NSString *)formLabelText textField:(STPFormTextField *)textField {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        UILabel *formLabel = [UILabel new];
        formLabel.text = formLabelText;
        formLabel.font = textField.font;
        formLabel.textColor = textField.defaultColor;
        // We want the textField to fill additional space so set the label's contentHuggingPriority to high
        [formLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

        formLabel.translatesAutoresizingMaskIntoConstraints = NO;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:formLabel];
        [self addSubview:textField];

        NSMutableArray<NSLayoutConstraint *> *constraints = [@[

            [formLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.widthAnchor multiplier:0.5f],

            [self.heightAnchor constraintGreaterThanOrEqualToConstant:kLabeledFormFieldHeight],

            [textField.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [formLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

            [[self.topAnchor anchorWithOffsetToAnchor:textField.topAnchor] constraintGreaterThanOrEqualToConstant:kLabeledFormVeriticalMargin],
            [[self.topAnchor anchorWithOffsetToAnchor:formLabel.topAnchor] constraintGreaterThanOrEqualToConstant:kLabeledFormVeriticalMargin],

            // constraining the height here works around an issue where UITextFields without a border style
            // change height slightly when they become or resign first responder
            [textField.heightAnchor constraintEqualToConstant:[textField systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height],
        ] mutableCopy];

        if (@available(iOS 11.0, *)) {
            [constraints addObjectsFromArray:@[
                [formLabel.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.layoutMarginsGuide.leadingAnchor multiplier:1.f],

                [textField.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:formLabel.trailingAnchor multiplier:2.f],
                [self.layoutMarginsGuide.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:textField.trailingAnchor multiplier:1.f],
            ]];
        } else {
            // Fallback on earlier versions
            [constraints addObjectsFromArray:@[
                [formLabel.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor constant:kLabeledFormiOS10EdgeInset],

                [textField.leadingAnchor constraintEqualToAnchor:formLabel.trailingAnchor constant:kLabeledFormHorizontalMargin],
                [self.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:textField.trailingAnchor constant:kLabeledFormiOS10EdgeInset],
            ]];
        }

        _labelWidthDimension = formLabel.widthAnchor;
        _formLabel = formLabel;

        [NSLayoutConstraint activateConstraints:constraints];
    }

    return self;
}

- (UIColor *)formBackgroundColor {
    return self.backgroundColor;
}

- (void)setFormBackgroundColor:(UIColor *)formBackgroundColor {
    self.backgroundColor = formBackgroundColor;
}

- (void)setFormLabelFont:(UIFont *)formLabelFont {
    _formLabel.font = formLabelFont;
}

- (UIFont *)formLabelFont {
    return _formLabel.font;
}

- (void)setFormLabelTextColor:(UIColor *)formLabelTextColor {
    _formLabel.textColor = formLabelTextColor;
}

- (UIColor *)formLabelTextColor {
    return _formLabel.textColor;
}


@end

NS_ASSUME_NONNULL_END
