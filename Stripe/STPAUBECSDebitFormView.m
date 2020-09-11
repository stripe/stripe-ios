//
//  STPAUBECSDebitFormView.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPAUBECSDebitFormView+Testing.h"

#import "STPAUBECSFormViewModel.h"
#import "STPFormTextField.h"
#import "STPLabeledFormTextFieldView.h"
#import "STPLabeledMultiFormTextFieldView.h"
#import "STPLocalizationUtils.h"
#import "STPMultiFormTextField.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPAUBECSDebitFormView () <STPMultiFormFieldDelegate, UITextViewDelegate> {
    STPAUBECSFormViewModel *_viewModel;

    STPFormTextField *_nameTextField;
    STPFormTextField *_emailTextField;
    STPFormTextField *_bsbNumberTextField;
    STPFormTextField *_accountNumberTextField;

    STPLabeledFormTextFieldView *_labeledNameField;
    STPLabeledFormTextFieldView *_labeledEmailField;
    STPLabeledMultiFormTextFieldView *_labeledBECSField;

    UIImageView *_bankIconView;
    UILabel *_bsbLabel;
    UITextView *_mandateLabel;

    NSString *_companyName;
}

@end

@implementation STPAUBECSDebitFormView

@synthesize formBackgroundColor = _formBackgroundColor;

-  (instancetype)initWithCompanyName:(NSString *)companyName {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _companyName = [companyName copy];
        [self _stp_commonInit];
    }

    return self;
}

- (UIColor *)formBackgroundColor {
    if (_formBackgroundColor != nil) {
        return _formBackgroundColor;
    } else {
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            return [UIColor systemBackgroundColor];
        } else
#endif
        {
            // Fallback on earlier versions
            return [UIColor whiteColor];
        }
    }
}

- (void)setFormBackgroundColor:(nullable UIColor *)formBackgroundColor {
    if (_formBackgroundColor != formBackgroundColor) {
        _formBackgroundColor = formBackgroundColor;
        _labeledNameField.formBackgroundColor = self.formBackgroundColor;
        _labeledEmailField.formBackgroundColor = self.formBackgroundColor;
        _labeledBECSField.formBackgroundColor = self.formBackgroundColor;
    }
}

- (nullable STPPaymentMethodParams *)paymentMethodParams {
    return _viewModel.paymentMethodParams;
}

- (STPFormTextField *)_buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.keyboardType = UIKeyboardTypeASCIICapableNumberPad;
    textField.textAlignment = NSTextAlignmentNatural;

    textField.font = self.formFont;
    textField.defaultColor = self.formTextColor;
    textField.errorColor = self.formTextErrorColor;
    textField.placeholderColor = self.formPlaceholderColor;
    textField.keyboardAppearance = self.formKeyboardAppearance;

    textField.validText = true;
    textField.selectionEnabled = YES;
    return textField;
}

+ (NSString *)_nameTextFieldLabel {
    return [STPLocalizationUtils localizedNameString];
}

+ (NSString *)_emailTextFieldLabel {
    return [STPLocalizationUtils localizedEmailString];
}

+ (NSString *)_bsbNumberTextFieldLabel {
    return [STPLocalizationUtils localizedBankAccountString];
}

+ (NSString *)_accountNumberTextFieldLabel {
    return [self _bsbNumberTextFieldLabel]; // same label
}

- (void)_stp_commonInit {
    _viewModel = [STPAUBECSFormViewModel new];

    _nameTextField = [self _buildTextField];
    _nameTextField.keyboardType = UIKeyboardTypeDefault;
    _nameTextField.placeholder = STPLocalizedString(@"Full name", @"Placeholder string for name entry field.");
    _nameTextField.textContentType = UITextContentTypeName;

    _emailTextField = [self _buildTextField];
    _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailTextField.placeholder = STPLocalizedString(@"example@example.com", @"Placeholder string for email entry field.");
    _emailTextField.textContentType = UITextContentTypeEmailAddress;

    _bsbNumberTextField = [self _buildTextField];
    _bsbNumberTextField.placeholder = STPLocalizedString(@"BSB", @"Placeholder text for BSB Number entry field for BECS Debit.");
    _bsbNumberTextField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorBSBNumber;
    _bsbNumberTextField.leftViewMode = UITextFieldViewModeAlways;
    _bankIconView = [[UIImageView alloc] init];
    _bankIconView.contentMode = UIViewContentModeCenter;
    _bankIconView.image = [_viewModel bankIconForInput:nil];
    _bankIconView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *iconContainer = [UIView new];
    [iconContainer addSubview:_bankIconView];
    iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _bsbNumberTextField.leftView = iconContainer;

    _accountNumberTextField = [self _buildTextField];
    _accountNumberTextField.placeholder = STPLocalizedString(@"Account number", @"Placeholder text for Account number entry field for BECS Debit.");


    STPLabeledFormTextFieldView *labeledNameField = [[STPLabeledFormTextFieldView alloc] initWithFormLabel:[[self class] _nameTextFieldLabel] textField:_nameTextField];
    labeledNameField.formBackgroundColor = self.formBackgroundColor;
    labeledNameField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:labeledNameField];
    _labeledNameField = labeledNameField;

    STPLabeledFormTextFieldView *labeledEmailField = [[STPLabeledFormTextFieldView alloc] initWithFormLabel:[[self class] _emailTextFieldLabel] textField:_emailTextField];
    labeledEmailField.topSeparatorHidden = YES;
    labeledEmailField.formBackgroundColor = self.formBackgroundColor;
    labeledEmailField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:labeledEmailField];
    _labeledEmailField = labeledEmailField;

    STPLabeledMultiFormTextFieldView *labeledBECSDetailsField = [[STPLabeledMultiFormTextFieldView alloc] initWithFormLabel:[[self class] _bsbNumberTextFieldLabel]
                                                                                                             firstTextField:_bsbNumberTextField
                                                                                                            secondTextField:_accountNumberTextField];
    labeledBECSDetailsField.formBackgroundColor = self.formBackgroundColor;
    labeledBECSDetailsField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:labeledBECSDetailsField];
    _labeledBECSField = labeledBECSDetailsField;


    _bsbLabel = [UILabel new];
    _bsbLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _bsbLabel.textColor = [self _defaultBSBLabelTextColor];
    _bsbLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_bsbLabel];

    UITextView *mandateTextLabel = [[UITextView alloc] init];
    mandateTextLabel.scrollEnabled = NO;
    mandateTextLabel.editable = NO;
    mandateTextLabel.selectable = YES;
    mandateTextLabel.backgroundColor = [UIColor clearColor];
    // Get rid of the extra padding added by default to UITextViews
    mandateTextLabel.textContainerInset = UIEdgeInsetsZero;
    mandateTextLabel.textContainer.lineFragmentPadding = 0.f;

    mandateTextLabel.delegate = self;

    NSMutableAttributedString *mandateText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the Direct Debit Request service agreement, and authorise Stripe Payments Australia Pty Ltd ACN 160 180 343 Direct Debit User ID number 507156 (\"Stripe\") to debit your account through the Bulk Electronic Clearing System (BECS) on behalf of %@ (the \"Merchant\") for any amounts separately communicated to you by the Merchant. You certify that you are either an account holder or an authorised signatory on the account listed above.", _companyName]];
    NSRange linkRange = [mandateText.string rangeOfString:@"Direct Debit Request service agreement"];
    if (linkRange.location != NSNotFound) {
        [mandateText addAttribute:NSLinkAttributeName value:@"https://stripe.com/au-becs-dd-service-agreement/legal" range:linkRange];
    } else {
        NSAssert(0, @"Shouldn't be missing the text to linkify.");
    }
    mandateTextLabel.attributedText = mandateText;
    // Set font and textColor after setting the attributedText so they are applied as attributes automatically
    mandateTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        mandateTextLabel.textColor = [UIColor secondaryLabelColor];
    } else
#endif
    {
        // Fallback on earlier versions
        mandateTextLabel.textColor = [UIColor darkGrayColor];
    }

    mandateTextLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:mandateTextLabel];
    _mandateLabel = mandateTextLabel;

    NSMutableArray<NSLayoutConstraint *> *constraints = [@[
        [_bankIconView.centerYAnchor constraintEqualToAnchor:iconContainer.centerYAnchor],
        [_bankIconView.topAnchor constraintEqualToAnchor:iconContainer.topAnchor constant:0],
        [_bankIconView.leadingAnchor constraintEqualToAnchor:iconContainer.leadingAnchor],
        [_bankIconView.trailingAnchor constraintEqualToAnchor:iconContainer.trailingAnchor constant:-8],

        [iconContainer.heightAnchor constraintGreaterThanOrEqualToAnchor:_bankIconView.heightAnchor multiplier:1.f],
        [iconContainer.widthAnchor constraintGreaterThanOrEqualToAnchor:_bankIconView.widthAnchor multiplier:1.f],

        [labeledNameField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [labeledNameField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [labeledNameField.topAnchor constraintEqualToAnchor:self.topAnchor],

        [labeledEmailField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [labeledEmailField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [labeledEmailField.topAnchor constraintEqualToAnchor:labeledNameField.bottomAnchor],

        [labeledNameField.labelWidthDimension constraintEqualToAnchor:labeledEmailField.labelWidthDimension],

        [labeledBECSDetailsField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [labeledBECSDetailsField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [labeledBECSDetailsField.topAnchor constraintEqualToAnchor:labeledEmailField.bottomAnchor constant:4],

        [_bsbLabel.topAnchor constraintEqualToAnchor:labeledBECSDetailsField.bottomAnchor constant:4],

        // Constrain to bottom of becs details instead of bank name label becuase it is height 0 when no data
        // has been entered
        [mandateTextLabel.topAnchor constraintEqualToAnchor:labeledBECSDetailsField.bottomAnchor constant:40.f],

        [self.bottomAnchor constraintEqualToAnchor:mandateTextLabel.bottomAnchor],

    ] mutableCopy];

    [constraints addObjectsFromArray:@[
        [_bsbLabel.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.layoutMarginsGuide.leadingAnchor multiplier:1.f],
        [self.layoutMarginsGuide.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:_bsbLabel.trailingAnchor multiplier:1.f],

        [mandateTextLabel.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.layoutMarginsGuide.leadingAnchor multiplier:1.f],
        [self.layoutMarginsGuide.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:mandateTextLabel.trailingAnchor multiplier:1.f],
    ]];

    [NSLayoutConstraint activateConstraints:constraints];

    self.formTextFields = @[_nameTextField, _emailTextField, _bsbNumberTextField, _accountNumberTextField];
    self.multiFormFieldDelegate = self;
}

- (void)_updateValidTextForField:(STPFormTextField *)formTextField {
    if (formTextField == _bsbNumberTextField) {
        formTextField.validText = [_viewModel isInputValid:formTextField.text
                                                  forField:STPAUBECSFormViewFieldBSBNumber
                                                   editing:[formTextField isFirstResponder]];
    } else if (formTextField == _accountNumberTextField) {
        formTextField.validText = [_viewModel isInputValid:formTextField.text
                                                  forField:STPAUBECSFormViewFieldAccountNumber
                                                   editing:[formTextField isFirstResponder]];
    } else if (formTextField == _nameTextField) {
        formTextField.validText = [_viewModel isInputValid:formTextField.text
                                                  forField:STPAUBECSFormViewFieldName
                                                   editing:[formTextField isFirstResponder]];
    } else if (formTextField == _emailTextField) {
        formTextField.validText = [_viewModel isInputValid:formTextField.text
                                                  forField:STPAUBECSFormViewFieldEmail
                                                   editing:[formTextField isFirstResponder]];
    } else {
        NSAssert(NO, @"Shouldn't call for text field not managed by %@", NSStringFromClass([self class]));
    }
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    // UITextViews don't play nice with autolayout, so we have to add a temporary height constraint
    // to get this method to account for the full, non-scrollable size of _mandateLabel
    [self layoutIfNeeded];
    NSLayoutConstraint *tempConstraint = [_mandateLabel.heightAnchor constraintEqualToConstant:_mandateLabel.contentSize.height];
    tempConstraint.active = YES;
    CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    tempConstraint.active = NO;
    return size;

}

- (UIColor *)_defaultBSBLabelTextColor {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    } else
#endif
    {
        // Fallback on earlier versions
        return [UIColor darkGrayColor];
    }
}

- (void)_updateBSBLabel {
    BOOL isErrorString = NO;
    _bsbLabel.text = [_viewModel bsbLabelForInput:_bsbNumberTextField.text editing:[_bsbNumberTextField isFirstResponder] isErrorString:&isErrorString];
    _bsbLabel.textColor = isErrorString ? self.formTextErrorColor : [self _defaultBSBLabelTextColor];
}

#pragma mark - STPMultiFormFieldDelegate

- (void)formTextFieldDidStartEditing:(STPFormTextField *)formTextField
                    inMultiFormField:(__unused STPMultiFormTextField *)multiFormField {
    [self _updateValidTextForField:formTextField];
    if (formTextField == _bsbNumberTextField) {
        [self _updateBSBLabel];
    }
}

- (void)formTextFieldDidEndEditing:(STPFormTextField *)formTextField
                  inMultiFormField:(__unused STPMultiFormTextField *)multiFormField {
    [self _updateValidTextForField:formTextField];
    if (formTextField == _bsbNumberTextField) {
        [self _updateBSBLabel];
    }
}

- (NSAttributedString *)modifiedIncomingTextChange:(NSAttributedString *)input
                                      forTextField:(STPFormTextField *)formTextField
                                  inMultiFormField:(__unused STPMultiFormTextField *)multiFormField {
    if (formTextField == _bsbNumberTextField) {
        return [[NSAttributedString alloc] initWithString:[_viewModel formattedStringForInput:input.string inField:STPAUBECSFormViewFieldBSBNumber]
                                               attributes:_bsbNumberTextField.defaultTextAttributes];
    } else if (formTextField == _accountNumberTextField) {
        return [[NSAttributedString alloc] initWithString:[_viewModel formattedStringForInput:input.string inField:STPAUBECSFormViewFieldAccountNumber]
                                               attributes:_accountNumberTextField.defaultTextAttributes];
    } else if (formTextField == _nameTextField) {
        return [[NSAttributedString alloc] initWithString:[_viewModel formattedStringForInput:input.string inField:STPAUBECSFormViewFieldName]
                                               attributes:_nameTextField.defaultTextAttributes];
    } else if (formTextField == _emailTextField) {
        return [[NSAttributedString alloc] initWithString:[_viewModel formattedStringForInput:input.string inField:STPAUBECSFormViewFieldEmail]
                                               attributes:_emailTextField.defaultTextAttributes];
    }  else {
        NSAssert(NO, @"Shouldn't call for text field not managed by %@", NSStringFromClass([self class]));
        return input;
    }
}

- (void)formTextFieldTextDidChange:(STPFormTextField *)formTextField
                  inMultiFormField:(__unused STPMultiFormTextField *)multiFormField {
    [self _updateValidTextForField:formTextField];

    BOOL hadCompletePaymentMethod = _viewModel.paymentMethodParams != nil;

    if (formTextField == _bsbNumberTextField) {
        _viewModel.bsbNumber = formTextField.text;

        [self _updateBSBLabel];
        _bankIconView.image = [_viewModel bankIconForInput:formTextField.text];

        // Since BSB number affects validity for the account number as well, we also need to update that field
        [self _updateValidTextForField:_accountNumberTextField];

        if ([_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldBSBNumber editing:[formTextField isFirstResponder]]) {
            [self focusNextFormField];
        }
    } else if (formTextField == _accountNumberTextField) {
        _viewModel.accountNumber = formTextField.text;
        if ([_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldAccountNumber editing:[formTextField isFirstResponder]]) {
            [self focusNextFormField];
        }
    } else if (formTextField == _nameTextField) {
        _viewModel.name = formTextField.text;
    } else if (formTextField == _emailTextField) {
        _viewModel.email = formTextField.text;
    } else {
        NSAssert(NO, @"Shouldn't call for text field not managed by %@", NSStringFromClass([self class]));
    }

    BOOL nowHasCompletePaymentMethod = _viewModel.paymentMethodParams != nil;
    if (hadCompletePaymentMethod != nowHasCompletePaymentMethod) {
        [self.becsDebitFormDelegate auBECSDebitForm:self didChangeToStateComplete:nowHasCompletePaymentMethod];
    }
}

- (BOOL)isFormFieldComplete:(STPFormTextField *)formTextField
           inMultiFormField:(__unused STPMultiFormTextField *)multiFormField {
    if (formTextField == _bsbNumberTextField) {
        return [_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldBSBNumber editing:NO];
    } else if (formTextField == _accountNumberTextField) {
        return [_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldAccountNumber editing:NO];
    } else if (formTextField == _nameTextField) {
        return [_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldName editing:NO];
    } else if (formTextField == _emailTextField) {
        return [_viewModel isFieldCompleteWithInput:formTextField.text inField:STPAUBECSFormViewFieldEmail editing:NO];
    }  else {
        NSAssert(NO, @"Shouldn't call for text field not managed by %@", NSStringFromClass([self class]));
        return NO;
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(__unused UITextView *)textView shouldInteractWithURL:(__unused NSURL *)URL inRange:(__unused NSRange)characterRange interaction:(__unused UITextItemInteraction)interaction {
    return YES;
}

#pragma mark - STPFormTextFieldContainer (Overrides)

- (void)setFormFont:(nullable UIFont *)formFont {
    [super setFormFont:formFont];
    _labeledNameField.formLabelFont = self.formFont;
    _labeledEmailField.formLabelFont = self.formFont;
}

- (void)setFormTextColor:(nullable UIColor *)formTextColor {
    [super setFormTextColor:formTextColor];
    _labeledNameField.formLabelTextColor = self.formTextColor;
    _labeledEmailField.formLabelTextColor = self.formTextColor;
}

@end

@implementation STPAUBECSDebitFormView (Testing)

- (STPFormTextField *)nameTextField {
    return _nameTextField;
}

- (STPFormTextField *)emailTextField {
    return _emailTextField;
}

- (STPFormTextField *)bsbNumberTextField {
    return _bsbNumberTextField;
}

- (STPFormTextField *)accountNumberTextField {
    return _accountNumberTextField;
}

@end

NS_ASSUME_NONNULL_END
