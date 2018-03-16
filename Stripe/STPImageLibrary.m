//
//  STPImages.m
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPImageLibrary.h"

#import "STPBundleLocator.h"
#import "STPImageLibrary+Private.h"

// Dummy class for locating the framework bundle

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

+ (UIImage *)unionPayCardImage {
    return [self brandImageForCardBrand:STPCardBrandUnionPay];
}

+ (UIImage *)visaCardImage {
    return [self brandImageForCardBrand:STPCardBrandVisa];
}

+ (UIImage *)unknownCardCardImage {
    return [self brandImageForCardBrand:STPCardBrandUnknown];
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)brand {
    return [self brandImageForCardBrand:brand template:NO];
}

+ (UIImage *)templatedBrandImageForCardBrand:(STPCardBrand)brand {
    return [self brandImageForCardBrand:brand template:YES];
}

+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)brand {
    NSString *imageName = brand == STPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self safeImageNamed:imageName];
}

+ (UIImage *)errorImageForCardBrand:(STPCardBrand)brand {
    NSString *imageName = brand == STPCardBrandAmex ? @"stp_card_error_amex" : @"stp_card_error";
    return [self safeImageNamed:imageName];
}

+ (UIImage *)safeImageNamed:(NSString *)imageName {
    return [self safeImageNamed:imageName templateIfAvailable:NO];
}

@end

@implementation STPImageLibrary (Private)

+ (UIImage *)addIcon {
    return [self safeImageNamed:@"stp_icon_add" templateIfAvailable:YES];
}

+ (UIImage *)checkmarkIcon {
    return [self safeImageNamed:@"stp_icon_checkmark" templateIfAvailable:YES];
}

+ (UIImage *)largeCardFrontImage {
    return [self safeImageNamed:@"stp_card_form_front" templateIfAvailable:YES];
}

+ (UIImage *)largeCardBackImage {
    return [self safeImageNamed:@"stp_card_form_back" templateIfAvailable:YES];
}

+ (UIImage *)largeShippingImage {
    return [self safeImageNamed:@"stp_shipping_form" templateIfAvailable:YES];
}

+ (UIImage *)safeImageNamed:(NSString *)imageName
        templateIfAvailable:(BOOL)templateIfAvailable {

    UIImage *image = [UIImage imageNamed:imageName inBundle:[STPBundleLocator stripeResourcesBundle] compatibleWithTraitCollection:nil];

    if (image == nil) {
        image = [UIImage imageNamed:imageName];
    }
    if (templateIfAvailable) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)brand 
                           template:(BOOL)isTemplate {
    BOOL shouldUseTemplate = isTemplate;
    NSString *imageName;
    switch (brand) {
        case STPCardBrandAmex:
            imageName = shouldUseTemplate ? @"stp_card_amex_template" : @"stp_card_amex";
            break;
        case STPCardBrandDinersClub:
            imageName = shouldUseTemplate ? @"stp_card_diners_template" : @"stp_card_diners";
            break;
        case STPCardBrandDiscover:
            imageName = shouldUseTemplate ? @"stp_card_discover_template" : @"stp_card_discover";
            break;
        case STPCardBrandJCB:
            imageName = shouldUseTemplate ? @"stp_card_jcb_template" : @"stp_card_jcb";
            break;
        case STPCardBrandMasterCard:
            imageName = shouldUseTemplate ? @"stp_card_mastercard_template" : @"stp_card_mastercard";
            break;
        case STPCardBrandUnionPay:
            if ([[[NSLocale currentLocale] localeIdentifier].lowercaseString hasPrefix:@"zh"]) {
                imageName = shouldUseTemplate ? @"stp_card_unionpay_template_zh" : @"stp_card_unionpay_zh";
            } else {
                imageName = shouldUseTemplate ? @"stp_card_unionpay_template_en" : @"stp_card_unionpay_en";
            }
            break;
        case STPCardBrandUnknown:
            shouldUseTemplate = YES;
            imageName = @"stp_card_unknown";
            break;
        case STPCardBrandVisa:
            imageName = shouldUseTemplate ? @"stp_card_visa_template" : @"stp_card_visa";
            break;
    }
    UIImage *image = [self safeImageNamed:imageName
                      templateIfAvailable:shouldUseTemplate];
    return image;
}

+ (UIImage *)imageWithTintColor:(UIColor *)color
                       forImage:(UIImage *)image {
    UIImage *newImage;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [color set];
    UIImage *templateImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [templateImage drawInRect:CGRectMake(0, 0, templateImage.size.width, templateImage.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
