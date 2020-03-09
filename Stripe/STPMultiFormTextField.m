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
    [[self _nextFirstResponderField] becomeFirstResponder];
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
    STPFormTextField *firstResponder = [self _currentFirstResponderField] ?: [self _nextFirstResponderField];
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

    return [self _firstInvalidSubField] ?: [self _lastSubField];
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
