//
//  STPFormTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormTextField.h"
#import "STPCardValidator.h"

@implementation STPFormTextField

- (void)setFormDelegate:(id<STPFormTextFieldDelegate>)formDelegate {
    _formDelegate = formDelegate;
    self.delegate = formDelegate;
}

- (void)deleteBackward {
    if (self.text.length == 0) {
        [self.formDelegate formTextFieldDidBackspaceOnEmpty:self];
    }
    [super deleteBackward];
}

- (CGSize)measureTextSize {
    return self.attributedText.size;
}

- (void)setText:(NSString *)text {
    NSAttributedString *attributed = [self attributedStringForString:text attributes:[self defaultTextAttributes]];
    [self setAttributedText:attributed];
}

- (NSAttributedString *)attributedStringForString:(NSString *)string attributes:(NSDictionary *)attributes {
    if (!string) {
        return nil;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
    if (self.formatsCardNumbers) {
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
            }
        }
    }
    return [attributedString copy];
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
    // TODO
}

- (void)updateColor {
    self.textColor = _validText ? self.defaultColor : self.errorColor;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self && self.ignoresTouches) {
        return nil;
    }
    return view;
}

@end
