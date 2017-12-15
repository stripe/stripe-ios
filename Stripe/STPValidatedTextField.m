//
//  STPValidatedTextField.m
//  StripeiOS
//
//  Created by Daniel Jackson on 12/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPValidatedTextField.h"

@implementation STPValidatedTextField

#pragma mark - Property Overrides

- (void)setDefaultColor:(UIColor *)defaultColor {
    _defaultColor = defaultColor;
    [self updateColor];
}

- (void)setErrorColor:(UIColor *)errorColor {
    _errorColor = errorColor;
    [self updateColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    // explicitly rebuild attributed placeholder to pick up new color
    [self setPlaceholder:self.placeholder];
}

- (void)setValidText:(BOOL)validText {
    _validText = validText;
    [self updateColor];
}

#pragma mark - UITextField overrides

- (void)setPlaceholder:(NSString *)placeholder {
    NSString *nonNilPlaceholder = placeholder ?: @"";
    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:nonNilPlaceholder attributes:[self placeholderTextAttributes]];
    [self setAttributedPlaceholder:attributedPlaceholder];
}

// Workaround for http://www.openradar.appspot.com/19374610
- (CGRect)editingRectForBounds:(CGRect)bounds {
    // danj: I still see a small vertical jump between the editingRect & textRect for text fields in
    // iOS 10.0-10.3 (but not 9.0 or 11.0-11.2). By using the textRect as the editingRect, this prevents
    // mismatches causing vertical mis-alignments
    return [self textRectForBounds:bounds];
}

#pragma mark - Private Methods

- (void)updateColor {
    self.textColor = _validText ? self.defaultColor : self.errorColor;
}

- (NSDictionary *)placeholderTextAttributes {
    NSMutableDictionary *defaultAttributes = [[self defaultTextAttributes] mutableCopy];
    if (self.placeholderColor) {
        defaultAttributes[NSForegroundColorAttributeName] = self.placeholderColor;
    }
    return [defaultAttributes copy];
}

@end
