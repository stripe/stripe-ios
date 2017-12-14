//
//  STPFormTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormTextField.h"

#import "NSString+Stripe.h"
#import "STPCardValidator.h"
#import "STPDelegateProxy.h"
#import "STPPhoneNumberValidator.h"
#import "STPWeakStrongMacros.h"

@interface STPTextFieldDelegateProxy : STPDelegateProxy<UITextFieldDelegate>
@property (nonatomic, assign) STPFormTextFieldAutoFormattingBehavior autoformattingBehavior;
@property (nonatomic, assign) BOOL selectionEnabled;
@end

@implementation STPTextFieldDelegateProxy

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL deleting = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    NSString *inputText;
    if (deleting) {
        NSString *sanitized = [self unformattedStringForString:textField.text];
        inputText = [sanitized stp_safeSubstringToIndex:sanitized.length - 1];
    } else {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *sanitized = [self unformattedStringForString:newString];
        inputText = sanitized;
    }
    
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextPosition *start = [textField positionFromPosition:beginning offset:range.location];
    
    if ([textField.text isEqualToString:inputText]) {
        return NO;
    }
    
    textField.text = inputText;
    
    if (self.autoformattingBehavior == STPFormTextFieldAutoFormattingBehaviorNone && self.selectionEnabled) {
        
        // this will be the new cursor location after insert/paste/typing
        NSInteger cursorOffset = [textField offsetFromPosition:beginning toPosition:start] + string.length;
        
        UITextPosition *newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
        UITextRange *newSelectedRange = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
        [textField setSelectedTextRange:newSelectedRange];
    }
    
    return NO;
}

- (NSString *)unformattedStringForString:(NSString *)string {
    switch (self.autoformattingBehavior) {
        case STPFormTextFieldAutoFormattingBehaviorNone:
            return string;
        case STPFormTextFieldAutoFormattingBehaviorCardNumbers:
        case STPFormTextFieldAutoFormattingBehaviorPhoneNumbers:
        case STPFormTextFieldAutoFormattingBehaviorExpiration:
            return [STPCardValidator sanitizedNumericStringForString:string];
    }
}

@end

typedef NSAttributedString* (^STPFormTextTransformationBlock)(NSAttributedString *inputText);

@interface STPFormTextField()
@property (nonatomic) STPTextFieldDelegateProxy *delegateProxy;
@property (nonatomic, copy) STPFormTextTransformationBlock textFormattingBlock;
@end

@implementation STPFormTextField

@synthesize placeholderColor = _placeholderColor;

+ (NSDictionary *)attributesForAttributedString:(NSAttributedString *)attributedString {
    if (attributedString.length == 0) {
        return @{};
    }
    return [attributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, attributedString.length)];
}

- (void)setSelectionEnabled:(BOOL)selectionEnabled {
    _selectionEnabled = selectionEnabled;
    self.delegateProxy.selectionEnabled = selectionEnabled;
}

- (void)setAutoFormattingBehavior:(STPFormTextFieldAutoFormattingBehavior)autoFormattingBehavior {
    _autoFormattingBehavior = autoFormattingBehavior;
    self.delegateProxy.autoformattingBehavior = autoFormattingBehavior;
    switch (autoFormattingBehavior) {
        case STPFormTextFieldAutoFormattingBehaviorNone:
        case STPFormTextFieldAutoFormattingBehaviorExpiration:
            self.textFormattingBlock = nil;
            if (@available(iOS 10, *)) {
                self.textContentType = nil;
            }
            break;
        case STPFormTextFieldAutoFormattingBehaviorCardNumbers:
            self.textFormattingBlock = ^NSAttributedString *(NSAttributedString *inputString) {
                if (![STPCardValidator stringIsNumeric:inputString.string]) {
                    return [inputString copy];
                }
                NSMutableAttributedString *attributedString = [inputString mutableCopy];
                NSArray *cardSpacing;
                STPCardBrand currentBrand = [STPCardValidator brandForNumber:attributedString.string];
                if (currentBrand == STPCardBrandAmex) {
                    cardSpacing = @[@3, @9];
                } else {
                    cardSpacing = @[@3, @7, @11];
                }
                for (NSUInteger i = 0; i < attributedString.length; i++) {
                    if ([cardSpacing containsObject:@(i)]) {
                        [attributedString addAttribute:NSKernAttributeName value:@(5)
                                                 range:NSMakeRange(i, 1)];
                    } else {
                        [attributedString addAttribute:NSKernAttributeName value:@(0)
                                                 range:NSMakeRange(i, 1)];
                    }
                }
                return [attributedString copy];
            };
            if (@available(iOS 10, *)) {
                self.textContentType = UITextContentTypeCreditCardNumber;
            }
            break;
        case STPFormTextFieldAutoFormattingBehaviorPhoneNumbers: {
            WEAK(self);
            self.textFormattingBlock = ^NSAttributedString *(NSAttributedString *inputString) {
                if (![STPCardValidator stringIsNumeric:inputString.string]) {
                    return [inputString copy];
                }
                STRONG(self);
                NSString *phoneNumber = [STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:inputString.string];
                NSDictionary *attributes = [[self class] attributesForAttributedString:inputString];
                return [[NSAttributedString alloc] initWithString:phoneNumber attributes:attributes];
            };
            if (@available(iOS 10, *)) {
                self.textContentType = UITextContentTypeTelephoneNumber;
            }
            break;
        }
    }
}

- (void)setFormDelegate:(id<STPFormTextFieldDelegate>)formDelegate {
    _formDelegate = formDelegate;
    self.delegate = formDelegate;
}

- (void)insertText:(NSString *)text {
    [self setText:[self.text stringByAppendingString:text]];
}

- (void)deleteBackward {
    [super deleteBackward];
    if (self.text.length == 0) {
        if ([self.formDelegate respondsToSelector:@selector(formTextFieldDidBackspaceOnEmpty:)]) {
            [self.formDelegate formTextFieldDidBackspaceOnEmpty:self];
        }
    }
}

- (void)setText:(NSString *)text {
    NSString *nonNilText = text ?: @"";
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:nonNilText attributes:self.defaultTextAttributes];
    [self setAttributedText:attributed];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSAttributedString *oldValue = [self attributedText];
    BOOL shouldModify = self.formDelegate && [self.formDelegate respondsToSelector:@selector(formTextField:modifyIncomingTextChange:)];
    NSAttributedString *modified = shouldModify ?
        [self.formDelegate formTextField:self modifyIncomingTextChange:attributedText] :
        attributedText;
    NSAttributedString *transformed = self.textFormattingBlock ? self.textFormattingBlock(modified) : modified;
    [super setAttributedText:transformed];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    if ([self.formDelegate respondsToSelector:@selector(formTextFieldTextDidChange:)]) {
        if (![transformed isEqualToAttributedString:oldValue]) {
            [self.formDelegate formTextFieldTextDidChange:self];
        }
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    NSString *nonNilPlaceholder = placeholder ?: @"";
    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:nonNilPlaceholder attributes:[self placeholderTextAttributes]];
    [self setAttributedPlaceholder:attributedPlaceholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    NSAttributedString *transformed = self.textFormattingBlock ? self.textFormattingBlock(attributedPlaceholder) : attributedPlaceholder;
    [super setAttributedPlaceholder:transformed];
}

- (NSDictionary *)placeholderTextAttributes {
    NSMutableDictionary *defaultAttributes = [[self defaultTextAttributes] mutableCopy];
    if (self.placeholderColor) {
        defaultAttributes[NSForegroundColorAttributeName] = self.placeholderColor;
    }
    return [defaultAttributes copy];
}

- (void)setDefaultColor:(UIColor *)defaultColor {
    _defaultColor = defaultColor;
    [self updateColor];
}

- (void)setErrorColor:(UIColor *)errorColor {
    _errorColor = errorColor;
    [self updateColor];
}

- (void)setValidText:(BOOL)validText {
    _validText = validText;
    [self updateColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    [self setPlaceholder:self.placeholder]; //explicitly rebuild attributed placeholder
}

- (void)updateColor {
    self.textColor = _validText ? self.defaultColor : self.errorColor;
}

// Workaround for http://www.openradar.appspot.com/19374610
- (CGRect)editingRectForBounds:(CGRect)bounds {
    // danj: I still see a small vertical jump between the editingRect & textRect for text fields in
    // iOS 10.0-10.3 (but not 9.0 or 11.0-11.2). By using the textRect as the editingRect, this prevents
    // mismatches causing vertical mis-alignments
    return [self textRectForBounds:bounds];
}

// Fixes a weird issue related to our custom override of deleteBackwards. This only affects the simulator and iPads with custom keyboards.
- (NSArray *)keyCommands {
    return @[[UIKeyCommand keyCommandWithInput:@"\b" modifierFlags:UIKeyModifierCommand action:@selector(commandDeleteBackwards)]];
}

- (void)commandDeleteBackwards {
    self.text = @"";
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    if (self.selectionEnabled) {
        return [super closestPositionToPoint:point];
    }
    return [self positionFromPosition:self.beginningOfDocument offset:self.text.length];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender] && action == @selector(paste:);
}

- (void)paste:(id)sender {
    if (self.preservesContentsOnPaste) {
        [super paste:sender];
    } else {
        self.text = [UIPasteboard generalPasteboard].string;
    }
}

- (void)setDelegate:(id <UITextFieldDelegate>)delegate {
    STPTextFieldDelegateProxy *delegateProxy = [[STPTextFieldDelegateProxy alloc] init];
    delegateProxy.autoformattingBehavior = self.autoFormattingBehavior;
    delegateProxy.selectionEnabled = self.selectionEnabled;
    delegateProxy.delegate = delegate;
    self.delegateProxy = delegateProxy;
    [super setDelegate:delegateProxy];
}

- (id <UITextFieldDelegate>)delegate {
    return self.delegateProxy;
}

@end
