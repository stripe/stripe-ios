//
//  STPLabeledMultiFormTextFieldView.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPLabeledMultiFormTextFieldView.h"

#import "STPFormTextField.h"
#import "STPLabeledFormTextFieldView.h"
#import "STPViewWithSeparator.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPLabeledMultiFormTextFieldView {
    STPViewWithSeparator *_fieldContainer;
}

- (instancetype)initWithFormLabel:(NSString *)formLabelText
                   firstTextField:(STPFormTextField *)textField1
                  secondTextField:(STPFormTextField *)textField2 {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        UILabel *formLabel = [UILabel new];
        formLabel.text = formLabelText;
        formLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            formLabel.textColor = [UIColor secondaryLabelColor];
        } else
#endif
        {
            // Fallback on earlier versions
            formLabel.textColor = [UIColor darkGrayColor];
        }
        formLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:formLabel];

        STPViewWithSeparator *fieldContainer = [STPViewWithSeparator new];
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            fieldContainer.backgroundColor = [UIColor systemBackgroundColor];
        } else
#endif
        {
            // Fallback on earlier versions
            fieldContainer.backgroundColor = [UIColor whiteColor];
        }

        textField1.translatesAutoresizingMaskIntoConstraints = NO;
        textField2.translatesAutoresizingMaskIntoConstraints = NO;
        [fieldContainer addSubview:textField1];
        [fieldContainer addSubview:textField2];

        fieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:fieldContainer];

        NSMutableArray<NSLayoutConstraint *> *constraints = [@[

            [formLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:kLabeledFormVeriticalMargin],

            [fieldContainer.topAnchor constraintEqualToAnchor:formLabel.bottomAnchor constant:kLabeledFormVeriticalMargin],
            [fieldContainer.heightAnchor constraintGreaterThanOrEqualToConstant:kLabeledFormFieldHeight],
            [self.bottomAnchor constraintEqualToAnchor:fieldContainer.bottomAnchor],
            [fieldContainer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [fieldContainer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

            [textField1.centerYAnchor constraintEqualToAnchor:fieldContainer.centerYAnchor],
            [textField2.centerYAnchor constraintEqualToAnchor:fieldContainer.centerYAnchor],

            [textField1.trailingAnchor constraintEqualToAnchor:self.centerXAnchor constant:-0.5f*kLabeledFormHorizontalMargin],
            [textField2.leadingAnchor constraintEqualToAnchor:self.centerXAnchor constant:0.5f*kLabeledFormHorizontalMargin],

            [[fieldContainer.topAnchor anchorWithOffsetToAnchor:textField1.topAnchor] constraintGreaterThanOrEqualToConstant:kLabeledFormVeriticalMargin],
            [[fieldContainer.topAnchor anchorWithOffsetToAnchor:textField2.topAnchor] constraintGreaterThanOrEqualToConstant:kLabeledFormVeriticalMargin],

            // constraining the height here works around an issue where UITextFields without a border style
            // change height slightly when they become or resign first responder
            [textField1.heightAnchor constraintEqualToConstant:[textField1 systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height],
            [textField2.heightAnchor constraintEqualToConstant:[textField2 systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height],
        ] mutableCopy];

        if (@available(iOS 11.0, *)) {
            [constraints addObjectsFromArray:@[
                [formLabel.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.layoutMarginsGuide.leadingAnchor multiplier:1.f],
                [self.layoutMarginsGuide.trailingAnchor constraintGreaterThanOrEqualToSystemSpacingAfterAnchor:formLabel.trailingAnchor multiplier:1.f],

                [textField1.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.layoutMarginsGuide.leadingAnchor multiplier:1.f],
                [self.layoutMarginsGuide.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:textField2.trailingAnchor multiplier:1.f],
            ]];
        } else {
            [constraints addObjectsFromArray:@[
                [formLabel.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor constant:kLabeledFormiOS10EdgeInset],
                [self.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:formLabel.trailingAnchor constant:kLabeledFormiOS10EdgeInset],

                [textField1.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor constant:kLabeledFormiOS10EdgeInset],
                [self.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:textField2.trailingAnchor constant:kLabeledFormiOS10EdgeInset],
            ]];
        }

        [NSLayoutConstraint activateConstraints:constraints];

        _fieldContainer = fieldContainer;
    }

    return self;
}

- (void)setFormBackgroundColor:(UIColor *)formBackgroundColor {
    _fieldContainer.backgroundColor = formBackgroundColor;
}

- (UIColor *)formBackgroundColor {
    return _fieldContainer.backgroundColor;
}

@end

NS_ASSUME_NONNULL_END
