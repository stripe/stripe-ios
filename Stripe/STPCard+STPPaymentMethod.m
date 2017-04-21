//
//  STPCard+STPPaymentMethod.m
//  Stripe
//
//  Created by Brian Dorfman on 4/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCard+STPPaymentMethod.h"

#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"

@implementation STPCard (STPPaymentMethod)

- (NSString *)label {
    NSString *brand = [self.class stringFromBrand:self.brand];
    return [NSString stringWithFormat:@"%@ %@", brand, self.last4];
}

- (UIImage *)image {
    return [STPImageLibrary brandImageForCardBrand:self.brand];
}

- (UIImage *)templateImage {
    return [STPImageLibrary templatedBrandImageForCardBrand:self.brand];
}

@end
