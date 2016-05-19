//
//  STPRememberMeTermsView.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPRememberMeTermsView.h"
#import "UIImage+Stripe.h"

@interface STPRememberMeTermsView()<UITextViewDelegate>

@property(nonatomic, weak)UITextView *textView;

@end

@implementation STPRememberMeTermsView

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

- (NSAttributedString *)buildAttributedString {
    NSString *privacyPolicy = NSLocalizedString(@"Privacy Policy", nil);
    NSURL *privacyURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/privacy"];
    NSString *terms = NSLocalizedString(@"Terms", nil);
    NSURL *termsURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/terms"];
    NSString *learnMore = NSLocalizedString(@"More info", nil);
    NSURL *learnMoreURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/remember-me"];
    NSString *contents = NSLocalizedString(@"By pressing Done, you’re electing to securely store your payment credentials and phone number with Stripe for use in this app and other apps. Your usage is subject to our Privacy Policy and Terms. More info", nil);
    NSRange privacyRange = [contents rangeOfString:privacyPolicy];
    NSRange termsRange = [contents rangeOfString:terms];
    NSRange learnMoreRange = [contents rangeOfString:learnMore];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSDictionary *attributes = @{
                                 NSFontAttributeName: self.theme.smallFont,
                                 NSForegroundColorAttributeName: self.theme.secondaryForegroundColor,
                                 NSParagraphStyleAttributeName: paragraphStyle,
                                 };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:contents
                                                                                         attributes:attributes];
    if (privacyRange.location != NSNotFound && privacyURL) {
        [attributedString addAttribute:NSLinkAttributeName value:privacyURL range:privacyRange];
    }
    if (termsRange.location != NSNotFound && termsURL) {
        [attributedString addAttribute:NSLinkAttributeName value:termsURL range:termsRange];
    }
    if (learnMoreRange.location != NSNotFound && learnMoreURL) {
        [attributedString addAttribute:NSLinkAttributeName value:learnMoreURL range:learnMoreRange];
    }
    if (learnMoreURL) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage stp_smallRightChevronIcon];
        NSMutableAttributedString *chevron = [[NSMutableAttributedString alloc] initWithString:@" " attributes:@{}];
        [chevron appendAttributedString:[NSMutableAttributedString attributedStringWithAttachment:attachment]];
        NSRange chevronRange = NSMakeRange(0, chevron.length);
        [chevron addAttribute:NSLinkAttributeName value:learnMoreURL range:chevronRange];
        [chevron addAttribute:NSBaselineOffsetAttributeName value:@(-1) range:chevronRange];
        [attributedString appendAttributedString:chevron];
    }
    return attributedString;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.textView.attributedText = [self buildAttributedString];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textView.frame = UIEdgeInsetsInsetRect(self.bounds, self.insets);
}

- (BOOL)textView:(__unused UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(__unused NSRange)characterRange {
    [[UIApplication sharedApplication] openURL:URL];
    return NO;
}

@end
