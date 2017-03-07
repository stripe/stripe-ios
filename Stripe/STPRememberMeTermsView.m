//
//  STPRememberMeTermsView.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPRememberMeTermsView.h"

#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPStringUtils.h"
#import "STPWebViewController.h"

@implementation STPRememberMeTermsView

static NSString *const FooterLinkTagPrivacyPolicy = @"pplink";
static NSString *const FooterLinkTagTermsOfService = @"termslink";
static NSString *const FooterLinkTagMoreInfo = @"infolink";

- (NSAttributedString *)buildAttributedString {
    __block NSString *contents = STPLocalizedString(@"Stripe may store my payment info and phone number for use in this app and other apps, and use my number for verification, subject to Stripe's <pplink>Privacy Policy</pplink> and <termslink>Terms</termslink>. <infolink>More Info</infolink>", 
                                                    @"Footer shown when the user enables Remember Me that shows additional info. The html-style tags control which parts of the text link to the Stripe Privacy Policy, Terms of Service, and Remember Me More Info pages, and can be moved around as needed in the translation (although they CANNOT overlap).");
    
    __block NSRange privacyRange;
    __block NSRange termsRange;
    __block NSRange learnMoreRange;
    
    [STPStringUtils parseRangesFromString:contents 
                                 withTags:[NSSet setWithArray:@[FooterLinkTagPrivacyPolicy, FooterLinkTagTermsOfService, FooterLinkTagMoreInfo]] 
                               completion:^(NSString *string, NSDictionary<NSString *,NSValue *> *tagMap) {
                                   contents = string;
                                   
                                   privacyRange = tagMap[FooterLinkTagPrivacyPolicy].rangeValue;
                                   termsRange = tagMap[FooterLinkTagTermsOfService].rangeValue;
                                   learnMoreRange = tagMap[FooterLinkTagMoreInfo].rangeValue;
                               }];
    
    NSURL *privacyURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/privacy"];
    NSURL *termsURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/terms"];
    NSURL *learnMoreURL = [NSURL URLWithString:@"https://checkout.stripe.com/-/remember-me"];
    
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

- (void)updateAppearance {
    self.textView.attributedText = [self buildAttributedString];
    self.textView.linkTextAttributes = @{
                                         NSFontAttributeName: self.theme.smallFont,
                                         NSForegroundColorAttributeName: self.theme.primaryForegroundColor
                                         };
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.pushViewControllerBlock) {
        STPWebViewController *webViewController = [[STPWebViewController alloc] initWithURL:URL 
                                                                                      title:[textView.text substringWithRange:characterRange]];
        self.pushViewControllerBlock(webViewController);
    }
    return NO;
}

@end
