//
//  STPFormTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormTextField.h"
#import "STPCardValidator.h"

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@implementation STPFormTextField

@synthesize placeholderColor = _placeholderColor;

- (void)setFormDelegate:(id<STPFormTextFieldDelegate>)formDelegate {
    _formDelegate = formDelegate;
    self.delegate = formDelegate;
}

- (void)deleteBackward {
    // This deliberately doesn't call super, because the superclass' implementation replaces text without calling delegate methods.
    if (self.text.length == 0) {
        [self.formDelegate formTextFieldDidBackspaceOnEmpty:self];
        return;
    }
    NSRange range = NSMakeRange(self.text.length - 1, 1);
    if ([self.delegate textField:self shouldChangeCharactersInRange:range replacementString:@""])  {
        self.text = [self.text stringByReplacingCharactersInRange:range withString:@""];
    }
}

- (CGSize)measureTextSize {
    return self.attributedText.size;
}

- (void)setText:(NSString *)text {
    NSAttributedString *attributed = [self attributedStringForString:text attributes:[self safeDefaultTextAttributes]];
    [self setAttributedText:attributed];
}

- (void)setPlaceholder:(NSString *)placeholder {
    NSMutableDictionary *attributes = [[self safeDefaultTextAttributes] mutableCopy];
    if (self.placeholderColor) {
        attributes[NSForegroundColorAttributeName] = self.placeholderColor;
    }
    NSAttributedString *attributed = [self attributedStringForString:placeholder attributes:[attributes copy]];
    [self setAttributedPlaceholder:attributed];
}

- (NSAttributedString *)attributedStringForString:(NSString *)string attributes:(NSDictionary *)attributes {
    if (!string) {
        return nil;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
    if (self.formatsCardNumbers && [STPCardValidator stringIsNumeric:string]) {
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
    }
    return [attributedString copy];
}

- (NSDictionary *)safeDefaultTextAttributes {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    if ([self respondsToSelector:@selector(defaultTextAttributes)]) {
        return [self defaultTextAttributes];
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (self.textColor) {
        attributes[NSForegroundColorAttributeName] = self.textColor;
    }
    if (self.font) {
        attributes[NSFontAttributeName] = self.font;
    }
    return [attributes copy];
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

@end
