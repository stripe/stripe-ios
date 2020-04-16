//
//  STPMultiFormTextField.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPMultiFormTextField.h"

#import "NSArray+Stripe.h"
#import "STPFormTextField.h"
#import "STPLabeledFormTextFieldView.h"
#import "STPLabeledMultiFormTextFieldView.h"
#import "STPViewWithSeparator.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPMultiFormTextField () <UITextFieldDelegate, STPFormTextFieldDelegate>
@end

@implementation STPMultiFormTextField

@synthesize formFont = _formFont;
@synthesize formKeyboardAppearance = _formKeyboardAppearance;
@synthesize formPlaceholderColor = _formPlaceholderColor;
@synthesize formTextColor = _formTextColor;
@synthesize formTextErrorColor = _formTextErrorColor;


- (void)setFormTextFields:(NSArray<STPFormTextField *> *)formTextFields {
    _formTextFields = formTextFields;
    for (STPFormTextField *field in formTextFields) {
        field.formDelegate = self;
    }
}

- (void)focusNextFormField {
    STPFormTextField *nextField = [self _nextFirstResponderField];
    if (nextField == [self _currentFirstResponderField]) {
        // If this doesn't actually advance us, resign first responder
        [nextField resignFirstResponder];
    } else {
        [nextField becomeFirstResponder];
    }
}

#pragma mark - UIResponder

- (BOOL)canResignFirstResponder {
    return [[self _currentFirstResponderField] canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [[self _currentFirstResponderField] resignFirstResponder];
    return success;
}

- (BOOL)isFirstResponder {
    return [self _currentFirstResponderField] != nil;
}

- (BOOL)canBecomeFirstResponder {
    STPFormTextField *firstResponder = [self _currentFirstResponderField] ?: [self _nextFirstResponderField];
    return [firstResponder canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    // Default to the first invalid subfield when becoming first responder
    STPFormTextField *firstResponder = [self _currentFirstResponderField] ?: [self _firstInvalidSubField];
    return [firstResponder becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    STPFormTextField *formTextField = [textField isKindOfClass:[STPFormTextField class]] ? (STPFormTextField *)textField : nil;

    if (formTextField != nil) {
        [self.multiFormFieldDelegate formTextFieldDidEndEditing:formTextField inMultiFormField:self];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    STPFormTextField *formTextField = [textField isKindOfClass:[STPFormTextField class]] ? (STPFormTextField *)textField : nil;
    if (formTextField != nil) {
        [self.multiFormFieldDelegate formTextFieldDidStartEditing:formTextField inMultiFormField:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    STPFormTextField *nextInSequence = [self _nextInSequenceFirstResponderField];
    if (nextInSequence != nil) {
        [nextInSequence becomeFirstResponder];
        return NO;
    } else {
        [textField resignFirstResponder];
        return YES;
    }
}

#pragma mark - UIKeyInput

- (BOOL)hasText {
    for (STPFormTextField *textField in self.formTextFields) {
        if (textField.hasText) {
            return YES;
        }
    }
    return NO;
}

- (void)insertText:(NSString *)text {
    [[self _currentFirstResponderField] insertText:text];
}

- (void)deleteBackward {
    [[self _currentFirstResponderField] deleteBackward];
}

#pragma mark - UITextInputTraits

@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;
@synthesize spellCheckingType = _spellCheckingType;
@synthesize smartQuotesType = _smartQuotesType;
@synthesize smartDashesType = _smartDashesType;
@synthesize smartInsertDeleteType = _smartInsertDeleteType;
@synthesize keyboardType = _keyboardType;
@synthesize keyboardAppearance = _keyboardAppearance;
@synthesize returnKeyType = _returnKeyType;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize textContentType = _textContentType;
@synthesize passwordRules = _passwordRules;

- (UITextAutocapitalizationType)autocapitalizationType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(autocapitalizationType)]) {
        return [currentFirstResponder autocapitalizationType];
    } else {
        return _autocapitalizationType;
    }
}

- (UITextAutocorrectionType)autocorrectionType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(autocorrectionType)]) {
        return [currentFirstResponder autocorrectionType];
    } else {
        return _autocorrectionType;
    }
}

- (UITextSpellCheckingType)spellCheckingType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(spellCheckingType)]) {
        return [currentFirstResponder spellCheckingType];
    } else {
        return _spellCheckingType;
    }
}

- (UITextSmartQuotesType)smartQuotesType  API_AVAILABLE(ios(11.0)) {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(smartQuotesType)]) {
        return [currentFirstResponder smartQuotesType];
    } else {
        return _smartQuotesType;
    }
}

- (UITextSmartDashesType)smartDashesType  API_AVAILABLE(ios(11.0)){
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(smartDashesType)]) {
        return [currentFirstResponder smartDashesType];
    } else {
        return _smartDashesType;
    }
}

- (UITextSmartInsertDeleteType)smartInsertDeleteType  API_AVAILABLE(ios(11.0)){
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(smartInsertDeleteType)]) {
        return [currentFirstResponder smartInsertDeleteType];
    } else {
        return _smartInsertDeleteType;
    }
}

- (UIKeyboardType)keyboardType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(keyboardType)]) {
        return [currentFirstResponder keyboardType];
    } else {
        return _keyboardType;
    }
}

- (UIKeyboardAppearance)keyboardAppearance {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(keyboardAppearance)]) {
        return [currentFirstResponder keyboardAppearance];
    } else {
        return _keyboardAppearance;
    }
}

- (UIReturnKeyType)returnKeyType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(returnKeyType)]) {
        return [currentFirstResponder returnKeyType];
    } else {
        return _returnKeyType;
    }
}

- (BOOL)enablesReturnKeyAutomatically {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(enablesReturnKeyAutomatically)]) {
        return [currentFirstResponder enablesReturnKeyAutomatically];
    } else {
        return _enablesReturnKeyAutomatically;
    }
}

- (BOOL)isSecureTextEntry {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(isSecureTextEntry)]) {
        return [currentFirstResponder isSecureTextEntry];
    } else {
        return _secureTextEntry;
    }
}

- (_Null_unspecified UITextContentType)textContentType {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(textContentType)]) {
        return [currentFirstResponder textContentType];
    } else {
        return _textContentType;
    }
}

- (nullable UITextInputPasswordRules *)passwordRules  API_AVAILABLE(ios(12.0)){
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if ([currentFirstResponder respondsToSelector:@selector(passwordRules)]) {
        return [currentFirstResponder passwordRules];
    } else {
        return _passwordRules;
    }
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self _previousField];
    [previous becomeFirstResponder];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    if (previous.hasText) {
        [previous deleteBackward];
    }
}

- (NSAttributedString *)formTextField:(STPFormTextField *)formTextField
             modifyIncomingTextChange:(NSAttributedString *)input {
    return [self.multiFormFieldDelegate modifiedIncomingTextChange:input
                                                      forTextField:formTextField
                                                  inMultiFormField:self];
}

- (void)formTextFieldTextDidChange:(STPFormTextField *)formTextField {
    [self.multiFormFieldDelegate formTextFieldTextDidChange:formTextField
                                           inMultiFormField:self];

    [self sendActionsForControlEvents:UIControlEventValueChanged];

}

#pragma mark - Helpers

- (nullable STPFormTextField *)_currentFirstResponderField {
    for (STPFormTextField *textField in self.formTextFields) {
        if ([textField isFirstResponder]) {
            return textField;
        }
    }
    return nil;
}

- (nullable STPFormTextField *)_previousField {
    STPFormTextField *currentSubResponder = [self _currentFirstResponderField];
    if (currentSubResponder) {
        NSUInteger index = [self.formTextFields indexOfObject:currentSubResponder];
        if (index != NSNotFound && index > 0) {
            return self.formTextFields[index - 1];
        }
    }
    return nil;
}

- (nonnull STPFormTextField *)_nextFirstResponderField {
    STPFormTextField *nextField = [self _nextInSequenceFirstResponderField];
    if (nextField != nil) {
        return nextField;
    } else {
        if ([self _currentFirstResponderField] == nil) {
            // if we don't currently have a first responder, consider the first invalid field the next one
            return [self _firstInvalidSubField];
        } else {
            return [self _lastSubField];
        }
    }
}

- (nullable STPFormTextField *)_nextInSequenceFirstResponderField {
    STPFormTextField *currentFirstResponder = [self _currentFirstResponderField];
    if (currentFirstResponder) {
        NSUInteger index = [self.formTextFields indexOfObject:currentFirstResponder];
        if (index != NSNotFound) {
            STPFormTextField *nextField = [self.formTextFields stp_boundSafeObjectAtIndex:index + 1];
            if (nextField != nil) {
                return nextField;
            }
        }
    }

    return nil;
}

- (nullable STPFormTextField *)_firstInvalidSubField {
    for (STPFormTextField *textField in self.formTextFields) {
        if (![self.multiFormFieldDelegate isFormFieldComplete:textField inMultiFormField:self]) {
            return textField;
        }
    }
    return nil;
}

- (nonnull STPFormTextField *)_lastSubField {
    return self.formTextFields.lastObject;
}

#pragma mark - STPFormTextFieldContainer

- (UIFont *)formFont {
    return _formFont ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)setFormFont:(nullable UIFont *)formFont {
    if (formFont != _formFont) {
        _formFont = formFont;
        for (STPFormTextField *textField in [self formTextFields]) {
            textField.font = self.formFont;
        }
    }
}

- (UIColor *)formTextColor {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return _formTextColor ?: [UIColor labelColor];
    } else
#endif
    {
        // Fallback on earlier versions
        return _formTextColor ?: [UIColor darkTextColor];
    }
}

- (void)setFormTextColor:(nullable UIColor *)formTextColor {
    if (_formTextColor != formTextColor) {
        _formTextColor = formTextColor;
        for (STPFormTextField *textField in [self formTextFields]) {
            textField.defaultColor = self.formTextColor;
        }
    }
}

- (UIColor *)formTextErrorColor {
    return _formTextErrorColor ?: [UIColor redColor];
}

- (void)setFormTextErrorColor:(nullable UIColor *)formTextErrorColor {
    if (_formTextErrorColor != formTextErrorColor) {
        _formTextErrorColor = formTextErrorColor;
        for (STPFormTextField *textField in [self formTextFields]) {
            textField.errorColor = self.formTextErrorColor;
        }
    }
}

- (UIColor *)formPlaceholderColor {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return _formPlaceholderColor ?: [UIColor placeholderTextColor];
    } else
#endif
    {
        // Fallback on earlier versions
        return _formPlaceholderColor ?: [UIColor lightGrayColor];
    }
}

- (void)setFormPlaceholderColor:(nullable UIColor *)formPlaceholderColor {
    if (_formPlaceholderColor != formPlaceholderColor) {
        _formPlaceholderColor = formPlaceholderColor;
        for (STPFormTextField *textField in [self formTextFields]) {
            textField.placeholderColor = self.formPlaceholderColor;
        }
    }
}

- (UIColor *)formCursorColor {
    return self.tintColor;
}

- (void)setFormCursorColor:(nullable UIColor *)formCursorColor {
    self.tintColor = formCursorColor;
    for (STPFormTextField *textField in [self formTextFields]) {
        textField.tintColor = self.formCursorColor;
    }
}

- (void)setFormKeyboardAppearance:(UIKeyboardAppearance)formKeyboardAppearance {
    if (_formKeyboardAppearance != formKeyboardAppearance) {
        _formKeyboardAppearance = formKeyboardAppearance;
        for (STPFormTextField *textField in [self formTextFields]) {
            textField.keyboardAppearance = self.formKeyboardAppearance;
        }
    }
}

@end

NS_ASSUME_NONNULL_END
