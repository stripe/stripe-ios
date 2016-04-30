//
//  STPFormTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormTextField.h"
#import "STPCardValidator.h"
#import "STPPhoneNumberValidator.h"
#import <Foundation/Foundation.h>
#import "TargetConditionals.h"
#import "NSString+Stripe.h"
#import "STPDelegateProxy.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPTextFieldDelegateProxy : STPDelegateProxy<UITextFieldDelegate>
@end

@implementation STPTextFieldDelegateProxy

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL deleting = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    NSString *inputText;
    if (deleting) {
        NSString *sanitized = [STPCardValidator sanitizedNumericStringForString:textField.text];
        inputText = [sanitized stp_safeSubstringToIndex:sanitized.length - 1];
    } else {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *sanitized = [STPCardValidator sanitizedNumericStringForString:newString];
        inputText = sanitized;
    }
    textField.text = inputText;
    return NO;
}

@end

typedef NSAttributedString* (^STPFormTextTransformationBlock)(NSAttributedString *inputText);

@interface STPFormTextField()
@property(nonatomic)STPTextFieldDelegateProxy *delegateProxy;
@property(nonatomic, copy)STPFormTextTransformationBlock textFormattingBlock;
@end

@implementation STPFormTextField

@synthesize placeholderColor = _placeholderColor;

+ (NSDictionary *)attributesForAttributedString:(NSAttributedString *)attributedString {
    if (attributedString.length == 0) {
        return @{};
    }
    return [attributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, attributedString.length)];
}

- (void)setAutoFormattingBehavior:(STPFormTextFieldAutoFormattingBehavior)autoFormattingBehavior {
    _autoFormattingBehavior = autoFormattingBehavior;
    switch (autoFormattingBehavior) {
        case STPFormTextFieldAutoFormattingBehaviorNone:
            self.textFormattingBlock = nil;
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
            break;
        case STPFormTextFieldAutoFormattingBehaviorPhoneNumbers: {
            __weak id weakself = self;
            self.textFormattingBlock = ^NSAttributedString *(NSAttributedString *inputString) {
                if (![STPCardValidator stringIsNumeric:inputString.string]) {
                    return [inputString copy];
                }
                __strong id strongself = weakself;
                NSString *phoneNumber = [STPPhoneNumberValidator formattedPhoneNumberForString:inputString.string];
                NSDictionary *attributes = [[strongself class] attributesForAttributedString:inputString];
                return [[NSAttributedString alloc] initWithString:phoneNumber attributes:attributes];
            };
            break;
        }
    }
}

- (void)setFormDelegate:(id<STPFormTextFieldDelegate>)formDelegate {
    _formDelegate = formDelegate;
    self.delegate = formDelegate;
}

- (void)deleteBackward {
    [super deleteBackward];
    if (self.text.length == 0) {
        [self.formDelegate formTextFieldDidBackspaceOnEmpty:self];
    }
}

- (CGSize)measureTextSize {
    return self.attributedText.size;
}

- (void)setText:(NSString *)text {
    NSString *nonNilText = text ?: @"";
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:nonNilText attributes:self.defaultTextAttributes];
    [self setAttributedText:attributed];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSAttributedString *modified = self.formDelegate ?
        [self.formDelegate formTextField:self modifyIncomingTextChange:attributedText] :
        attributedText;
    NSAttributedString *transformed = self.textFormattingBlock ? self.textFormattingBlock(modified) : modified;
    [super setAttributedText:transformed];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.065;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.layer addAnimation:transition forKey:nil];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    [self.formDelegate formTextFieldTextDidChange:self];
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
    if (UIDevice.currentDevice.systemVersion.integerValue != 8) {
        return [self textRectForBounds:bounds];
    }
    
    CGFloat const scale = UIScreen.mainScreen.scale;
    CGFloat const preferred = self.attributedText.size.height;
    CGFloat const delta = (CGFloat)ceil(preferred) - preferred;
    CGFloat const adjustment = (CGFloat)floor(delta * scale) / scale;
    
    CGRect const textRect = [self textRectForBounds:bounds];
    CGRect const editingRect = CGRectOffset(textRect, 0.0, adjustment);
    
    return editingRect;
}

// Fixes a weird issue related to our custom override of deleteBackwards. This only affects the simulator and iPads with custom keyboards.
- (NSArray *)keyCommands {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    return @[[UIKeyCommand keyCommandWithInput:@"\b" modifierFlags:UIKeyModifierCommand action:@selector(commandDeleteBackwards)]];
}

- (void)commandDeleteBackwards {
    self.text = @"";
}

- (UITextPosition *)closestPositionToPoint:(__unused CGPoint)point {
    return [self positionFromPosition:self.beginningOfDocument offset:self.text.length];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return [super canPerformAction:action withSender:sender] && action == @selector(paste:);
}

- (void)paste:(__unused id)sender {
    self.text = [UIPasteboard generalPasteboard].string;
}

- (void)setDelegate:(id <UITextFieldDelegate>)delegate {
    STPTextFieldDelegateProxy *delegateProxy = [[STPTextFieldDelegateProxy alloc] init];
    delegateProxy.delegate = delegate;
    self.delegateProxy = delegateProxy;
    [super setDelegate:delegateProxy];
}

- (id <UITextFieldDelegate>)delegate {
    return self.delegateProxy;
}

@end
