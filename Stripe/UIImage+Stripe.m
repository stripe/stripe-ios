//
//  UIImage+Stripe.m
//  Stripe
//
//  Created by Ben Guo on 1/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIImage+Stripe.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

// Dummy class for locating the framework bundle
@interface STPBundleLocator : NSObject
@end
@implementation STPBundleLocator
@end

@implementation UIImage (Stripe)

+ (UIImage *)stp_addIcon {
    return [self.class stp_safeImageNamed:@"stp_icon_add" templateifAvailable:YES];
}

+ (UIImage *)stp_leftChevronIcon {
    return [self.class stp_safeImageNamed:@"stp_icon_chevron_left" templateifAvailable:YES];
}

+ (UIImage *)stp_smallRightChevronIcon {
    return [self.class stp_safeImageNamed:@"stp_icon_chevron_right_small" templateifAvailable:YES];
}

+ (nonnull UIImage *)stp_largeCardFrontImage {
    return [self.class stp_safeImageNamed:@"stp_card_form_front" templateifAvailable:YES];
}

+ (nonnull UIImage *)stp_largeCardBackImage {
    return [self.class stp_safeImageNamed:@"stp_card_form_back" templateifAvailable:YES];
}

+ (UIImage *)stp_largeCardApplePayImage {
    return [self.class stp_safeImageNamed:@"stp_card_form_applepay" templateifAvailable:YES];
}

+ (UIImage *)stp_applePayCardImage {
    return [self.class stp_safeImageNamed:@"stp_card_applepay"];
}

+ (UIImage *)stp_amexCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandAmex];
}

+ (UIImage *)stp_dinersClubCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandDinersClub];
}

+ (UIImage *)stp_discoverCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandDiscover];
}

+ (UIImage *)stp_jcbCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandJCB];
}

+ (UIImage *)stp_masterCardCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandMasterCard];
}

+ (UIImage *)stp_visaCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandVisa];
}

+ (UIImage *)stp_unknownCardCardImage {
    return [self.class stp_brandImageForCardBrand:STPCardBrandUnknown];
}

+ (UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSString *imageName;
    BOOL templateSupported = [[self.class new] respondsToSelector:@selector(imageWithRenderingMode:)];
    switch (brand) {
        case STPCardBrandAmex:
            imageName = @"stp_card_amex";
            break;
        case STPCardBrandDinersClub:
            imageName = @"stp_card_diners";
            break;
        case STPCardBrandDiscover:
            imageName = @"stp_card_discover";
            break;
        case STPCardBrandJCB:
            imageName = @"stp_card_jcb";
            break;
        case STPCardBrandMasterCard:
            imageName = @"stp_card_mastercard";
            break;
        case STPCardBrandUnknown:
            imageName = templateSupported ? @"stp_card_placeholder_template" : @"stp_card_placeholder";
            break;
        case STPCardBrandVisa:
            imageName = @"stp_card_visa";
    }
    UIImage *image = [self.class stp_safeImageNamed:imageName];
    if (brand == STPCardBrandUnknown && templateSupported) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand {
    NSString *imageName = brand == STPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self.class stp_safeImageNamed:imageName];
}

+ (UIImage *)stp_safeImageNamed:(NSString *)imageName
            templateifAvailable:(BOOL)templateIfAvailable {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    BOOL templateSupported = [[self.class new] respondsToSelector:@selector(imageWithRenderingMode:)];
    UIImage *image;
    if ([[self.class class] respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        image = [self.class imageNamed:imageName inBundle:[NSBundle bundleForClass:[STPBundleLocator class]] compatibleWithTraitCollection:nil];
    }
    image = [self.class imageNamed:imageName];
    if (templateSupported && templateIfAvailable) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)stp_safeImageNamed:(NSString *)imageName {
    return [self stp_safeImageNamed:imageName templateifAvailable:NO];
}

- (UIImage *)stp_paddedImageWithInsets:(UIEdgeInsets)insets {
    CGSize size = CGSizeMake(self.size.width + insets.left + insets.right,
                             self.size.height + insets.top + insets.bottom);
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    CGPoint origin = CGPointMake(insets.left, insets.top);
    [self drawAtPoint:origin];
    UIImage *imageWithInsets = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    BOOL templateSupported = [self respondsToSelector:@selector(imageWithRenderingMode:)];
    if (templateSupported) {
        imageWithInsets = [imageWithInsets imageWithRenderingMode:self.renderingMode];
    }
    return imageWithInsets;
}

@end

void linkUIImageCategory(void){}
