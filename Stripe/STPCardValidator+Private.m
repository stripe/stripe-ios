//
//  STPCardValidator+Private.m
//  StripeiOS
//
//  Created by Cameron Sabol on 8/6/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPCardValidator+Private.h"
#import "STPBINRange.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPCardValidator (Private)

+ (NSArray<NSNumber *> *)cardNumberFormatForBrand:(STPCardBrand)brand
{
    switch (brand) {
        case STPCardBrandAmex:
            return @[@4, @6, @5];
        default:
            return @[@4, @4, @4, @4];
    }
}

+ (NSArray<NSNumber *> *)cardNumberFormatForCardNumber:(NSString *)cardNumber
{
    STPBINRange *binRange = [STPBINRange mostSpecificBINRangeForNumber:cardNumber];
    if (binRange.brand == STPCardBrandDinersClub && binRange.length == 14) {
        return @[@4, @6, @4];
    }

    return [self cardNumberFormatForBrand:binRange.brand];
}

@end

NS_ASSUME_NONNULL_END

void linkSTPCardValidatorPrivateCategory(void){}
