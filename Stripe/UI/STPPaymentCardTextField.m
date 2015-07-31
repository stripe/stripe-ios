//
//  STPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;

#import "Stripe.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentCardTextFieldViewModel.h"
#import "STPFormTextField.h"
#import "STPCardValidator.h"

@interface STPPaymentCardTextField()<STPFormTextFieldDelegate>

@property(nonatomic, readwrite, strong)STPFormTextField *sizingField;

@property(nonatomic, readwrite, weak)UITextField *backgroundTextField;

@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UIView *interstitialView;

@property(nonatomic, readwrite, weak)STPFormTextField *numberField;
@property(nonatomic, readwrite, weak)NSLayoutConstraint *numberLeftConstraint;
@property(nonatomic, readwrite, weak)NSLayoutConstraint *numberWidthConstraint;

@property(nonatomic, readwrite, weak)UIView *dateContainer;
@property(nonatomic, readwrite, weak)NSLayoutConstraint *dateContainerLeftConstraint;

@property(nonatomic, readwrite, weak)STPFormTextField *expirationField;
@property(nonatomic, readwrite, weak)NSLayoutConstraint *expirationWidthConstraint;

@property(nonatomic, readwrite, weak)STPFormTextField *cvcField;
@property(nonatomic, readwrite, weak)NSLayoutConstraint *cvcWidthConstraint;

@property(nonatomic, readwrite, strong)STPPaymentCardTextFieldViewModel *viewModel;

@property(nonatomic, readwrite, weak)UITextField *selectedField;

@end

@implementation STPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@synthesize borderStyle = _borderStyle;

#pragma mark initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {

    self.clipsToBounds = YES;
    
    _viewModel = [STPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];
    
    STPFormTextField *backgroundTextField = [self buildTextField];
    backgroundTextField.borderStyle = self.borderStyle;
    backgroundTextField.ignoresTouches = YES;
    _backgroundTextField = backgroundTextField;

    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:_viewModel.brandImage];
    brandImageView.translatesAutoresizingMaskIntoConstraints = NO;
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    self.brandImageView = brandImageView;
    
    UIView *interstitialView = [[UIView alloc] initWithFrame:CGRectZero];
    interstitialView.backgroundColor = self.backgroundColor;
    interstitialView.translatesAutoresizingMaskIntoConstraints = NO;
    self.interstitialView = interstitialView;
    
    STPFormTextField *numberField = [self buildTextField];
    numberField.formatsCardNumbers = YES;
    numberField.tag = STPCardFieldTypeNumber;
    numberField.placeholder = [self.viewModel placeholder];
    self.numberField = numberField;
    
    UIView *dateContainer = [[UIView alloc] initWithFrame:CGRectZero];
    dateContainer.backgroundColor = self.backgroundColor;
    dateContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateContainer = dateContainer;

    STPFormTextField *expirationField = [self buildTextField];
    expirationField.tag = STPCardFieldTypeExpiration;
    expirationField.placeholder = @"MM/YY";
    expirationField.alpha = 0;
    self.expirationField = expirationField;
        
    STPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = STPCardFieldTypeCVC;
    cvcField.placeholder = @"CVC";
    cvcField.alpha = 0;
    self.cvcField = cvcField;
    
    [dateContainer addSubview:expirationField];
    [self addSubview:cvcField];
    [self addSubview:dateContainer];
    [self addSubview:numberField];
    [self addSubview:interstitialView];
    [self addSubview:brandImageView];
    [self addSubview:backgroundTextField];
    
    [self setupConstraints];
}

- (STPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [STPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[backgroundColor copy]];
    self.numberField.backgroundColor = self.backgroundColor;
    self.interstitialView.backgroundColor = self.backgroundColor;
    self.dateContainer.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    return [super backgroundColor] ?: [UIColor whiteColor];
}

- (void)setFont:(UIFont *)font {
    _font = [font copy];
    
    for (UITextField *field in [self allFields]) {
        field.font = _font;
    }
    
    self.sizingField.font = _font;
    
    self.numberWidthConstraint.constant = [self widthForCardNumber:self.numberField.placeholder];
    self.expirationWidthConstraint.constant = [self widthForText:self.expirationField.placeholder];
    self.cvcWidthConstraint.constant = MAX([self widthForText:self.cvcField.placeholder], [self widthForText:@"8888"]);
    
    [self setNeedsUpdateConstraints];
}

- (UIFont *)font {
    return _font ?: [UIFont systemFontOfSize:18];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.defaultColor = _textColor;
    }
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor blackColor];
}

- (void)setTextErrorColor:(UIColor *)textErrorColor {
    _textErrorColor = [textErrorColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.errorColor = _textErrorColor;
    }
}

- (UIColor *)textErrorColor {
    return _textErrorColor ?: [UIColor redColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = [placeholderColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.placeholderColor = _placeholderColor;
    }
}

- (UIColor *)placeholderColor {
    return _placeholderColor ?: [UIColor lightGrayColor];
}

- (void)setBorderStyle:(UITextBorderStyle)borderStyle {
    _borderStyle = borderStyle;
    self.backgroundTextField.borderStyle = borderStyle;
}

- (UITextBorderStyle)borderStyle {
    return _borderStyle ?: UITextBorderStyleRoundedRect;
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    
    for (STPFormTextField *field in [self allFields]) {
        field.inputAccessoryView = inputAccessoryView;
    }
}

#pragma mark UIResponder & related methods

- (BOOL)canBecomeFirstResponder {
    return [self.numberField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.numberField becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [self.selectedField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    BOOL success = [self.selectedField resignFirstResponder];
    [self setNumberFieldShrunk:[self shouldShrinkNumberField] animated:YES];
    return success;
}

- (BOOL)canSelectNextField {
    return [[self nextField] canBecomeFirstResponder];
}

- (BOOL)canSelectPreviousField {
    return [[self previousField] canBecomeFirstResponder];
}

- (BOOL)selectNextField {
    return [[self nextField] becomeFirstResponder];
}

- (BOOL)selectPreviousField {
    return [[self previousField] becomeFirstResponder];
}

- (STPFormTextField *)nextField {
    if (self.selectedField == self.numberField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.cvcField;
    }
    return nil;
}

- (STPFormTextField *)previousField {
    if (self.selectedField == self.cvcField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.numberField;
    }
    return nil;
}

#pragma mark public convenience methods

- (void)clear {
    for (STPFormTextField *field in [self allFields]) {
        field.text = @"";
    }
//    self.viewModel =
    [self setNumberFieldShrunk:NO animated:YES];
}

- (BOOL)hasValidContents {
    return [self.viewModel isValid];
}

#pragma mark readonly variables

- (NSString *)cardNumber {
    return self.viewModel.cardNumber;
}

- (NSUInteger)expirationMonth {
    return [self.viewModel.expirationMonth integerValue];
}

- (NSUInteger)expirationYear {
    return [self.viewModel.expirationYear integerValue];
}

- (NSString *)cvc {
    return self.viewModel.cvc;
}

#pragma mark - private helper methods

- (STPFormTextField *)buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.formDelegate = self;
    return textField;
}

- (NSArray *)allFields {
    return @[self.numberField, self.expirationField, self.cvcField];
}

- (void)setupConstraints {
    
    // Background text view
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundTextField
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundTextField
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    // Image view
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.brandImageView
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0f
                                                      constant:10.0f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.interstitialView
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.interstitialView
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.brandImageView
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0f
                                                      constant:10.0f]];
    
    // Number field
    NSLayoutConstraint *numberLeftConstraint = [NSLayoutConstraint constraintWithItem:self.numberField
                                                                            attribute:NSLayoutAttributeLeft
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.interstitialView
                                                                            attribute:NSLayoutAttributeRight
                                                                           multiplier:1.0f
                                                                             constant:0.0f];
    self.numberLeftConstraint = numberLeftConstraint;
    [self addConstraint:numberLeftConstraint];
    
    NSLayoutConstraint *numberWidthConstraint = [NSLayoutConstraint constraintWithItem:self.numberField
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:nil
                                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                                            multiplier:1.0f
                                                                              constant:[self widthForCardNumber:self.numberField.placeholder]];
    self.numberWidthConstraint = numberWidthConstraint;
    [self addConstraint:numberWidthConstraint];
    
    //Expiration field
    NSLayoutConstraint *dateLeftConstraint = [NSLayoutConstraint constraintWithItem:self.dateContainer
                                                                          attribute:NSLayoutAttributeLeft
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.brandImageView
                                                                          attribute:NSLayoutAttributeRight
                                                                         multiplier:1.0f
                                                                           constant:10.0f];
    self.dateContainerLeftConstraint = dateLeftConstraint;
    [self addConstraint:dateLeftConstraint];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.dateContainer
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.cvcField
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0f
                                                      constant:-10.0f]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.expirationField
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.dateContainer
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    NSLayoutConstraint *expirationWidthConstraint = [NSLayoutConstraint constraintWithItem:self.expirationField
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0f
                                                                             constant:[self widthForText:self.expirationField.placeholder]];
    
    self.expirationWidthConstraint = expirationWidthConstraint;
    [self addConstraint:expirationWidthConstraint];
    
    // CVC field
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.cvcField
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    NSLayoutConstraint *cvcWidthConstraint = [NSLayoutConstraint constraintWithItem:self.cvcField
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0f
                                                                           constant:MAX([self widthForText:self.cvcField.placeholder], [self widthForText:@"8888"])];
    
    self.cvcWidthConstraint = cvcWidthConstraint;
    [self addConstraint:cvcWidthConstraint];
    
    // Make everything be 100% height and vertically centered
    for (UIView *view in @[self.backgroundTextField, self.brandImageView, self.interstitialView, self.dateContainer, self.numberField, self.expirationField, self.cvcField]) {
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:view.superview
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:view.superview
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
    }
}

- (void)setNumberFieldShrunk:(BOOL)shrunk animated:(BOOL)animated {
    
    CGFloat nonFragmentWidth = [self widthForCardNumber:[self.viewModel numberWithoutLastDigits]] - 16;
    CGFloat fragmentWidth = self.numberWidthConstraint.constant - nonFragmentWidth;
    
    if (shrunk) {
        self.dateContainerLeftConstraint.constant = fragmentWidth + 10.0f;
        [self layoutSubviews];
    }
    
    [UIView animateWithDuration:(animated * 0.3) animations:^{
        self.numberLeftConstraint.constant = shrunk ? -nonFragmentWidth : 0;
        for (UIView *view in @[self.expirationField, self.cvcField]) {
            view.alpha = 1.0f * shrunk;
        }
        [self layoutSubviews];
    } completion:^(__unused BOOL finished) {
        if (!shrunk) {
            self.dateContainerLeftConstraint.constant = 10.0f;
            [self layoutSubviews];
        }
    }];
    
}

- (BOOL)shouldShrinkNumberField {
    return [self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid;
}

- (CGFloat)widthForText:(NSString *)text {
    self.sizingField.formatsCardNumbers = NO;
    [self.sizingField setText:text];
    return [self.sizingField measureTextSize].width + 8;
}

- (CGFloat)widthForTextWithLength:(NSUInteger)length {
    NSString *text = [@"" stringByPaddingToLength:length withString:@"M" startingAtIndex:0];
    return [self widthForText:text];
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    self.sizingField.formatsCardNumbers = YES;
    [self.sizingField setText:cardNumber];
    return [self.sizingField measureTextSize].width + 15;
}

#pragma mark STPPaymentTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    [previous deleteBackward];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.selectedField = (STPFormTextField *)textField;
    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            [self setNumberFieldShrunk:NO animated:YES];
            break;
            
        default:
            break;
    }
    if (textField == self.cvcField) {
        self.brandImageView.image = self.viewModel.cvcImage;
    } else {
        self.brandImageView.image = self.viewModel.brandImage;
    }
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField {
    self.selectedField = nil;
}

- (BOOL)textField:(STPFormTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    BOOL deletingLastCharacter = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    if (deletingLastCharacter && [textField.text hasSuffix:@"/"] && range.location > 0) {
        range.location -= 1;
        range.length += 1;
    }
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    STPCardFieldType fieldType = textField.tag;
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            self.viewModel.cardNumber = newText;
            textField.text = self.viewModel.cardNumber;
            break;
        case STPCardFieldTypeExpiration: {
            self.viewModel.rawExpiration = newText;
            textField.text = self.viewModel.rawExpiration;
            break;
        }
        case STPCardFieldTypeCVC:
            self.viewModel.cvc = newText;
            textField.text = self.viewModel.cvc;
            break;
    }
    
    if (fieldType == STPCardFieldTypeCVC) {
        self.brandImageView.image = self.viewModel.cvcImage;
    } else {
        self.brandImageView.image = self.viewModel.brandImage;
    }

    STPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    textField.validText = YES;
    switch (state) {
        case STPCardValidationStateInvalid:
            textField.validText = NO;
            break;
        case STPCardValidationStatePossible:
            break;
        case STPCardValidationStateValid: {
            [self selectNextField];
            if (fieldType == STPCardFieldTypeNumber) {
                [self setNumberFieldShrunk:YES animated:YES];
            }
            break;
        }
    }
    [self onChange];

    return NO;
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    if ([self hasValidContents]) {
        [self.delegate paymentCardTextFieldDidValidateSuccessfully:self];
    }
}

@end
