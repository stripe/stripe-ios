//
//  STPRememberMeTermsView.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPRememberMeTermsView.h"
#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"

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
    NSString *privacyPolicy = STPLocalizedString(@"Privacy Policy", @"The text in the full Remember Me TOS/privacy footer to turn into a link to the privacy policy URL. NOTE: this must _EXACTLY_ match a substring in the full remember me footer text");
    NSURL *privacyURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/privacy"];
    NSString *terms = STPLocalizedString(@"Terms", @"The text in the full Remember Me TOS/privacy footer to turn into a link to the terns of service URL. NOTE: this must _EXACTLY_ match a substring in the full remember me footer text");
    NSURL *termsURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/terms"];
    NSString *learnMore = STPLocalizedString(@"More Info", @"The text in the full Remember Me TOS/privacy footer to turn into a link to the more info URL. NOTE: this must _EXACTLY_ match a substring in the full remember me footer text");
    NSURL *learnMoreURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/remember-me"];
    NSString *contents = STPLocalizedString(@"Stripe may store my payment info and phone number for use in this app and other apps, and use my number for verification, subject to Stripe's Privacy Policy and Terms. More Info", 
                                            @"Footer shown when user enables Remember Me that show additional info. If you change/localize this, you _MUST_ change the Privacy Policy, Terms, and More Info strings to match.");
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
        attachment.image = [STPImageLibrary smallRightChevronIcon];
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
    self.textView.linkTextAttributes = @{
                                         NSFontAttributeName: self.theme.smallFont,
                                         NSForegroundColorAttributeName: self.theme.primaryForegroundColor
                                         };
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
