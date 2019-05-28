//
//  STPCardBrand.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 5/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPCardBrand.h"

NSString * STPStringFromCardBrand(STPCardBrand brand) {
    switch (brand) {
        case STPCardBrandAmex:
            return @"American Express";
        case STPCardBrandDinersClub:
            return @"Diners Club";
        case STPCardBrandDiscover:
            return @"Discover";
        case STPCardBrandJCB:
            return @"JCB";
        case STPCardBrandMasterCard:
            return @"MasterCard";
        case STPCardBrandUnionPay:
            return @"UnionPay";
        case STPCardBrandVisa:
            return @"Visa";
        case STPCardBrandUnknown:
            return @"Unknown";
    }
}

STPCardBrand STPCardBrandFromString(NSString *string) {
    // Documentation: https://stripe.com/docs/api#card_object-brand
    NSString *brand = [string lowercaseString];
    if ([brand isEqualToString:@"visa"]) {
        return STPCardBrandVisa;
    } else if ([brand isEqualToString:@"american express"]) {
        return STPCardBrandAmex;
    } else if ([brand isEqualToString:@"mastercard"]) {
        return STPCardBrandMasterCard;
    } else if ([brand isEqualToString:@"discover"]) {
        return STPCardBrandDiscover;
    } else if ([brand isEqualToString:@"jcb"]) {
        return STPCardBrandJCB;
    } else if ([brand isEqualToString:@"diners club"]) {
        return STPCardBrandDinersClub;
    } else if ([brand isEqualToString:@"unionpay"]) {
        return STPCardBrandUnionPay;
    } else {
        return STPCardBrandUnknown;
    }
}
