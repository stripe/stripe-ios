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

+ (BOOL)stringIsValidLuhn:(NSString *)number {
    BOOL odd = true;
    int sum = 0;
    NSMutableArray *digits = [NSMutableArray arrayWithCapacity:number.length];
    
    for (int i = 0; i < (NSInteger)number.length; i++) {
        [digits addObject:[number substringWithRange:NSMakeRange(i, 1)]];
    }
    
    for (NSString *digitStr in [digits reverseObjectEnumerator]) {
        int digit = [digitStr intValue];
        if ((odd = !odd)) digit *= 2;
        if (digit > 9) digit -= 9;
        sum += digit;
    }
    
    return sum % 10 == 0;
}

@end

NS_ASSUME_NONNULL_END

void linkSTPCardValidatorPrivateCategory(void){}
