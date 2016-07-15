//
//  STPImages.m
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

// Dummy class for locating the framework bundle
@interface STPBundleLocator : NSObject
@end
@implementation STPBundleLocator
@end

@implementation STPImageLibrary

+ (UIImage *)applePayCardImage {
    return [self safeImageNamed:@"stp_card_applepay"];
}

+ (UIImage *)amexCardImage {
    return [self brandImageForCardBrand:STPCardBrandAmex];
}

+ (UIImage *)dinersClubCardImage {
    return [self brandImageForCardBrand:STPCardBrandDinersClub];
}

+ (UIImage *)discoverCardImage {
    return [self brandImageForCardBrand:STPCardBrandDiscover];
}

+ (UIImage *)jcbCardImage {
    return [self brandImageForCardBrand:STPCardBrandJCB];
}

+ (UIImage *)masterCardCardImage {
    return [self brandImageForCardBrand:STPCardBrandMasterCard];
}

+ (UIImage *)visaCardImage {
    return [self brandImageForCardBrand:STPCardBrandVisa];
}

+ (UIImage *)unknownCardCardImage {
    return [self brandImageForCardBrand:STPCardBrandUnknown];
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)brand {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSString *imageName;
    BOOL templateSupported = [self templateSupported];
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
    UIImage *image = [self safeImageNamed:imageName];
    if (brand == STPCardBrandUnknown && templateSupported) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)brand {
    NSString *imageName = brand == STPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self safeImageNamed:imageName];
}

+ (UIImage *)safeImageNamed:(NSString *)imageName
            templateifAvailable:(BOOL)templateIfAvailable {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    UIImage *image = nil;
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        image = [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[STPBundleLocator class]] compatibleWithTraitCollection:nil];
    }
    if (image == nil) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"Stripe.bundle/%@", imageName]];
    }
    if (image == nil) {
        image = [UIImage imageNamed:imageName];
    }
    if ([self templateSupported] && templateIfAvailable) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)safeImageNamed:(NSString *)imageName {
    return [self safeImageNamed:imageName templateifAvailable:NO];
}

+ (BOOL)templateSupported {
    return [[UIImage class] instancesRespondToSelector:@selector(imageWithRenderingMode:)];
}

@end

@implementation STPImageLibrary (Private)

+ (UIImage *)addIcon {
    return [self safeImageNamed:@"stp_icon_add" templateifAvailable:YES];
}

+ (UIImage *)leftChevronIcon {
    return [self safeImageNamed:@"stp_icon_chevron_left" templateifAvailable:YES];
}

+ (UIImage *)smallRightChevronIcon {
    return [self safeImageNamed:@"stp_icon_chevron_right_small" templateifAvailable:YES];
}

+ (UIImage *)largeCardFrontImage {
    return [self safeImageNamed:@"stp_card_form_front" templateifAvailable:YES];
}

+ (UIImage *)largeCardBackImage {
    return [self safeImageNamed:@"stp_card_form_back" templateifAvailable:YES];
}

+ (UIImage *)largeCardApplePayImage {
    return [self safeImageNamed:@"stp_card_form_applepay" templateifAvailable:YES];
}

+ (UIImage *)imageWithTintColor:(UIColor *)color
                       forImage:(UIImage *)image {
    UIImage *newImage;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [color set];
    UIImage *templateImage = image;
    if ([self templateSupported]) {
        templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [templateImage drawInRect:CGRectMake(0, 0, templateImage.size.width, templateImage.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)paddedImageWithInsets:(UIEdgeInsets)insets
                          forImage:(UIImage *)image {
    CGSize size = CGSizeMake(image.size.width + insets.left + insets.right,
                             image.size.height + insets.top + insets.bottom);
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGPoint origin = CGPointMake(insets.left, insets.top);
    [image drawAtPoint:origin];
    UIImage *imageWithInsets = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if ([self templateSupported]) {
        imageWithInsets = [imageWithInsets imageWithRenderingMode:image.renderingMode];
    }
    return imageWithInsets;
}

@end
