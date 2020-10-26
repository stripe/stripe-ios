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
            return @"Mastercard";
        case STPCardBrandUnionPay:
            return @"UnionPay";
        case STPCardBrandVisa:
            return @"Visa";
        case STPCardBrandUnknown:
            return @"Unknown";
    }
}
