//
//  STPInfoFooterView.m
//  Stripe
//
//  Created by Ben Guo on 3/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPInfoFooterView.h"

@interface STPInfoFooterView()

@property(nonatomic, weak)UITextView *textView;

@end

@implementation STPInfoFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UITextView *textView = [[UITextView alloc] initWithFrame:self.bounds];
        textView.backgroundColor = [UIColor clearColor];
        [self addSubview:textView];
        textView.editable = NO;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.scrollEnabled = NO;
        textView.delegate = self;

        // This disables 3D touch previews in the text view.
        for (UIGestureRecognizer *recognizer in textView.gestureRecognizers) {
            if ([[NSStringFromClass([recognizer class]) lowercaseString] containsString:@"preview"] ||
                [[NSStringFromClass([recognizer class]) lowercaseString] containsString:@"reveal"]) {
                recognizer.enabled = NO;
            }
        }
        _textView = textView;
        _theme = [STPTheme new];
        _insets = UIEdgeInsetsMake(10, 15, 0, 15);
        [self updateAppearance];
    }
    return self;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.textView.font = self.theme.smallFont;
    self.textView.textColor = self.theme.secondaryForegroundColor;
    self.textView.linkTextAttributes = @{
                                         NSFontAttributeName: self.theme.smallFont,
                                         NSForegroundColorAttributeName: self.theme.primaryForegroundColor
                                         };
}

- (CGFloat)heightForWidth:(CGFloat)maxWidth {
    CGFloat availableWidth = maxWidth - (self.insets.left + self.insets.right);
    return ([self.textView sizeThatFits:CGSizeMake(availableWidth, CGFLOAT_MAX)].height
            + self.insets.top
            + self.insets.bottom);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textView.frame = UIEdgeInsetsInsetRect(self.bounds, self.insets);
}

- (void)setInsets:(UIEdgeInsets)insets {
    _insets = insets;
    [self setNeedsLayout];
}

@end
