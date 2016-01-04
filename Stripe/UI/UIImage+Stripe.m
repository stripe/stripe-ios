//
//  UIImage+Stripe.m
//  Stripe
//
//  Created by Ben Guo on 1/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIImage+Stripe.h"
#import "STPPaymentCardTextFieldViewModel.h"

@implementation UIImage (Stripe)

+ (UIImage *)stp_amexCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandAmex];
}

+ (UIImage *)stp_dinersClubCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandDinersClub];
}

+ (UIImage *)stp_discoverCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandDiscover];
}

+ (UIImage *)stp_jcbCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandJCB];
}

+ (UIImage *)stp_masterCardCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandMasterCard];
}

+ (UIImage *)stp_visaCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandVisa];
}

+ (UIImage *)stp_unknownCardCardImage {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:STPCardBrandUnknown];
}

@end

void linkUIImageCategory(void){}
