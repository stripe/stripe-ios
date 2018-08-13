//
//  STPCardValidator+Private.m
//  StripeiOS
//
//  Created by Cameron Sabol on 8/6/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPCardValidator+Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPCardValidator (Private)

+ (NSArray<NSNumber *> *)cardNumberFormatForBrand:(STPCardBrand)brand
{
    switch (brand) {
        case STPCardBrandAmex:
            return @[@4, @6, @5];
        case STPCardBrandDinersClub:
            return @[@4, @6, @4];
        default:
            return @[@4, @4, @4, @4];
    }
}

@end

NS_ASSUME_NONNULL_END

void linkSTPCardValidatorPrivateCategory(void){}
