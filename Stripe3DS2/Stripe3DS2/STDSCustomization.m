//
//  STDSCustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSCustomization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSCustomization

- (id)copyWithZone:(nullable NSZone *)zone {
    STDSCustomization *copy = [[[self class] allocWithZone:zone] init];
    copy.font = self.font;
    copy.textColor = self.textColor;

    return copy;
}

@end

NS_ASSUME_NONNULL_END
