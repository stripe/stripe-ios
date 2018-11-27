//
//  STPCardValidator+Private.h
//  StripeiOS
//
//  Created by Cameron Sabol on 8/6/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPCardValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCardValidator (Private)

+ (NSArray<NSNumber *> *)cardNumberFormatForBrand:(STPCardBrand)brand;

@end

NS_ASSUME_NONNULL_END

void linkSTPCardValidatorPrivateCategory(void);
