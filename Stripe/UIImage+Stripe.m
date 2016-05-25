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

+ (UIImage *)stp_amexCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandAmex];
}

+ (UIImage *)stp_dinersClubCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandDinersClub];
}

+ (UIImage *)stp_discoverCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandDiscover];
}

+ (UIImage *)stp_jcbCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandJCB];
}

+ (UIImage *)stp_masterCardCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandMasterCard];
}

+ (UIImage *)stp_visaCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandVisa];
}

+ (UIImage *)stp_unknownCardCardImage {
    return [self stp_brandImageForCardBrand:STPCardBrandUnknown];
}

+ (UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSString *imageName;
    BOOL templateSupported = [[self new] respondsToSelector:@selector(imageWithRenderingMode:)];
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
    UIImage *image = [self stp_safeImageNamed:imageName];
    if (brand == STPCardBrandUnknown && templateSupported) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand {
    NSString *imageName = brand == STPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self stp_safeImageNamed:imageName];
}

+ (UIImage *)stp_safeImageNamed:(NSString *)imageName {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    if ([self respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        return [self imageNamed:imageName inBundle:[NSBundle bundleForClass:[STPBundleLocator class]] compatibleWithTraitCollection:nil];
    }
    return [self imageNamed:imageName];
}

@end

void linkUIImageCategory(void){}
